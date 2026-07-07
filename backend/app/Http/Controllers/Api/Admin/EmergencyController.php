<?php

namespace App\Http\Controllers\Api\Admin;

use App\Domain\Blood\BloodCompatibility;
use App\Events\EmergencyAlertActivated;
use App\Events\EmergencyCommitmentUpdated;
use App\Events\MobileNotificationCreated;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreEmergencyAlertRequest;
use App\Http\Resources\BloodJourneyResource;
use App\Http\Resources\EmergencyAlertResource;
use App\Http\Resources\EmergencyCommitmentResource;
use App\Models\BloodJourney;
use App\Models\DonationHistory;
use App\Models\EmergencyAlert;
use App\Models\EmergencyCommitment;
use App\Models\Hospital;
use App\Models\MobileNotification;
use App\Services\Admin\AdminUserResolver;
use App\Services\Contracts\EmergencyAlertRealtimeGateway;
use App\Services\Donations\DonationRecognitionService;
use App\Services\Emergency\EmergencyDispatchService;
use App\Services\Mobile\MobileUserResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Throwable;

class EmergencyController extends Controller
{
    public function __construct(
        private readonly EmergencyDispatchService $dispatchService,
        private readonly MobileUserResolver $mobileUserResolver,
        private readonly AdminUserResolver $adminUserResolver,
        private readonly EmergencyAlertRealtimeGateway $realtimeGateway,
        private readonly DonationRecognitionService $recognitionService,
        private readonly BloodCompatibility $bloodCompatibility,
        private readonly \App\Services\Gratitude\GratitudeMessageService $gratitudeService,
    ) {}

    public function store(StoreEmergencyAlertRequest $request)
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'sos.activate'), 403);

        $hospital = Hospital::query()->findOrFail($request->integer('hospital_id'));
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $hospital->id), 403);

        $payload = [
            ...$request->validated(),
            'created_by' => $admin->id,
        ];
        $alert = $this->dispatchService->activate($hospital, $payload);

        return EmergencyAlertResource::make($alert)
            ->response()
            ->setStatusCode(201);
    }

    public function show(Request $request, EmergencyAlert $alert): EmergencyAlertResource
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $alert->hospital_id), 403);

        return EmergencyAlertResource::make(
            $alert->load('hospital.province', 'hospital.ward', 'recipients.donor.province', 'commitments.donor.province', 'commitments.bloodJourney.steps')
        );
    }

    public function cancel(EmergencyAlert $alert): EmergencyAlertResource
    {
        $admin = $this->adminUserResolver->resolve(request());
        abort_unless($this->adminUserResolver->hasPermission($admin, 'sos.activate'), 403);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $alert->hospital_id), 403);

        $alert->update(['status' => 'cancelled']);
        $alert->load('hospital.province', 'hospital.ward', 'recipients.donor.province', 'commitments.donor.province', 'commitments.bloodJourney.steps');
        $this->realtimeGateway->publish($alert);
        $this->broadcastAlert($alert);

        return EmergencyAlertResource::make($alert->refresh()->load('hospital.province', 'hospital.ward', 'recipients.donor.province', 'commitments.donor.province', 'commitments.bloodJourney.steps'));
    }

    public function complete(Request $request, EmergencyAlert $alert): EmergencyAlertResource
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'sos.activate'), 403);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $alert->hospital_id), 403);

        DB::transaction(function () use ($alert): void {
            $alert->update(['status' => 'fulfilled']);

            $lateCommitments = $alert->commitments()
                ->whereIn('status', ['committed', 'en_route'])
                ->get();

            foreach ($lateCommitments as $commitment) {
                $commitment->update(['status' => 'not_needed', 'last_location_at' => now()]);
                $this->createMobileNotification(
                    $commitment->donor_id,
                    'sos_fulfilled',
                    'Ca SOS đã nhận đủ máu',
                    'Cảm ơn bạn, ca hiến máu này đã nhận đủ đơn vị máu cần thiết. Hệ thống đã lưu ghi nhận và xin hẹn bạn ở lượt tiếp theo nhé!',
                    ['alert_id' => $alert->public_id],
                );
                $this->broadcastCommitment($commitment->refresh()->load('donor.province', 'donor.ward', 'alert.hospital'));
            }
        });

        $alert->load('hospital.province', 'hospital.ward', 'recipients.donor.province', 'commitments.donor.province', 'commitments.bloodJourney.steps');
        $this->realtimeGateway->publish($alert);
        $this->broadcastAlert($alert);

        return EmergencyAlertResource::make($alert->refresh()->load('hospital.province', 'hospital.ward', 'recipients.donor.province', 'commitments.donor.province', 'commitments.bloodJourney.steps'));
    }

    public function mobileIndex(Request $request): JsonResponse
    {
        $donor = $this->mobileUserResolver->resolve($request->integer('user_id'));

        $alerts = EmergencyAlert::query()
            ->with([
                'hospital.province',
                'hospital.ward',
                'commitments' => function ($query) use ($donor): void {
                    $query
                        ->where('donor_id', $donor->id)
                        ->whereIn('status', ['committed', 'en_route', 'cancelled', 'donated', 'not_needed'])
                        ->latest();
                },
            ])
            ->where('expires_at', '>', now())
            ->whereIn('status', ['active', 'cancelled', 'fulfilled'])
            ->latest()
            ->limit(20)
            ->get()
            ->filter(fn (EmergencyAlert $alert): bool => $this->bloodCompatibility->canDonateTo(
                $donor->blood_type,
                $alert->required_blood_type,
            ))
            ->each(function (EmergencyAlert $alert): void {
                $alert->setRelation('currentCommitment', $alert->commitments->first());
            })
            ->values();

        return response()->json([
            'data' => EmergencyAlertResource::collection($alerts)->resolve(),
        ]);
    }

    public function mobileActiveCommitment(Request $request): JsonResponse
    {
        $donor = $this->mobileUserResolver->resolve($request->integer('user_id'));

        $commitment = EmergencyCommitment::query()
            ->with([
                'alert.hospital.province',
                'alert.hospital.ward',
                'donor.province',
                'donor.ward',
            ])
            ->where('donor_id', $donor->id)
            ->whereIn('status', ['committed', 'en_route'])
            ->whereHas('alert', function ($query): void {
                $query
                    ->where('status', 'active')
                    ->where('expires_at', '>', now());
            })
            ->orderByRaw('COALESCE(last_location_at, committed_at, created_at) DESC')
            ->first();

        if (! $commitment) {
            return response()->json(['data' => null]);
        }

        return response()->json([
            'data' => [
                'alert' => EmergencyAlertResource::make($commitment->alert)->resolve(),
                'commitment' => EmergencyCommitmentResource::make($commitment)->resolve(),
            ],
        ]);
    }

    public function mobileRealtimeConfig(Request $request): JsonResponse
    {
        $reverb = config('broadcasting.connections.reverb', []);
        $options = $reverb['options'] ?? [];
        $scheme = (string) (env('MOBILE_REVERB_SCHEME') ?: ($options['scheme'] ?? ($request->isSecure() ? 'https' : 'http')));
        $host = (string) (env('MOBILE_REVERB_HOST') ?: env('REVERB_PUBLIC_HOST') ?: ($options['host'] ?? $request->getHost()));
        $port = (int) (env('MOBILE_REVERB_PORT') ?: ($options['port'] ?? ($scheme === 'https' ? 443 : 80)));

        if (str_contains($host, '://')) {
            $parts = parse_url($host);
            $scheme = (string) ($parts['scheme'] ?? $scheme);
            $host = (string) ($parts['host'] ?? $host);
            $port = (int) ($parts['port'] ?? $port);
        }

        if (in_array($host, ['0.0.0.0', '127.0.0.1', 'localhost'], true) && $request->getHost() !== $host) {
            $host = $request->getHost();
        }

        $key = (string) ($reverb['key'] ?? '');

        return response()->json([
            'data' => [
                'enabled' => config('broadcasting.default') === 'reverb' && $key !== '' && $host !== '',
                'broadcaster' => 'reverb',
                'key' => $key,
                'host' => $host,
                'port' => $port,
                'scheme' => $scheme,
                'channels' => [
                    'global' => 'mobile.emergency-alerts',
                    'donor' => 'mobile.donor.{donor_id}',
                ],
                'events' => [
                    'alert_activated' => 'emergency.alert.activated',
                    'commitment_updated' => 'emergency.commitment.updated',
                    'notification_created' => 'mobile.notification.created',
                ],
            ],
        ]);
    }

    public function markCommitmentDonated(Request $request, EmergencyAlert $alert, EmergencyCommitment $commitment): EmergencyCommitmentResource
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'sos.activate'), 403);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $alert->hospital_id), 403);
        abort_unless((int) $commitment->emergency_alert_id === (int) $alert->id, 404);

        $payload = $request->validate([
            'volume_ml' => ['required', 'integer', Rule::in([250, 350, 450])],
            'donated_at' => ['nullable', 'date'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $commitment->load('donor', 'alert.hospital');
        $donatedAt = isset($payload['donated_at'])
            ? Carbon::parse($payload['donated_at'])
            : now();
        $volumeMl = $payload['volume_ml'];

        $commitment = DB::transaction(function () use ($alert, $admin, $commitment, $donatedAt, $volumeMl, $payload): EmergencyCommitment {
            // Chống double-submit: khóa hàng commitment và đọc lại trạng thái NGAY TRONG
            // transaction. Nếu admin bấm xác nhận nhiều lần, chỉ lần đầu tiên mới tính là
            // "mới hiến" — tránh cộng điểm và tạo thông báo cảm ơn trùng lặp.
            $locked = EmergencyCommitment::query()->lockForUpdate()->findOrFail($commitment->id);
            $alreadyDonated = $locked->status === 'donated' || $locked->donation_history_id !== null;

            $certificateId = 'SOS-'.$alert->id.'-'.$commitment->id;
            $history = DonationHistory::query()->updateOrCreate(
                ['certificate_id' => $certificateId],
                $this->recognitionService->prepareCertificateAttributes([
                    'user_id' => $commitment->donor_id,
                    'hospital_id' => $alert->hospital_id,
                    'donation_type' => 'sos',
                    'donated_at' => $donatedAt->toDateString(),
                    'location_name' => $alert->hospital->name,
                    'volume_ml' => $volumeMl,
                    'blood_type' => $commitment->donor->blood_type,
                    'certificate_title' => 'Chứng nhận hiến máu khẩn cấp '.$alert->public_id,
                    'status' => 'verified',
                    'notes' => $payload['notes'] ?? 'Xác nhận hiến máu từ ca SOS '.$alert->public_id,
                ]),
            );

            // Tự động đồng bộ sang kho máu (BloodStock)
            \App\Models\BloodStock::updateOrCreate(
                ['donation_history_id' => $history->id],
                [
                    'hospital_id' => $alert->hospital_id,
                    'blood_type' => $commitment->donor->blood_type,
                    'volume_ml' => $volumeMl,
                    'received_date' => $history->donated_at,
                    'expiry_date' => \Illuminate\Support\Carbon::parse($history->donated_at)->addDays(35)->toDateString(),
                    'status' => 'available',
                    'notes' => 'Hiến máu khẩn cấp SOS từ ca cấp cứu: ' . $alert->public_id,
                ]
            );

            $commitment->update([
                'status' => 'donated',
                'donation_volume_ml' => $volumeMl,
                'donated_at' => $donatedAt,
                'verified_at' => now(),
                'verified_by' => $admin->id,
                'donation_history_id' => $history->id,
                'last_location_at' => now(),
            ]);

            if (! $alreadyDonated) {
                $this->recognitionService->awardNewDonation(
                    $commitment->donor,
                    'sos',
                    $donatedAt,
                );
            }

            $journey = $this->ensureBloodJourney($alert, $commitment, $history);

            if (! $alreadyDonated) {
                $this->createMobileNotification(
                    $commitment->donor_id,
                    'donation_verified',
                    'Cảm ơn bạn đã hiến máu cứu người',
                    "Chứng nhận hiến máu SOS của bạn đã được ghi nhận. Cảm ơn nghĩa cử cao đẹp của bạn!",
                    ['blood_journey_id' => $journey->public_id, 'destination_type' => $journey->destination_type]
                );
            }

            return $commitment->refresh()->load('donor.province', 'donor.ward', 'alert.hospital', 'bloodJourney.hospital', 'bloodJourney.steps');
        });

        $this->broadcastCommitment($commitment);
        $this->evaluateAlertFulfillment($alert);

        return EmergencyCommitmentResource::make($commitment);
    }

    public function updateCommitmentJourney(Request $request, EmergencyAlert $alert, EmergencyCommitment $commitment): BloodJourneyResource
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'sos.activate'), 403);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $alert->hospital_id), 403);
        abort_unless((int) $commitment->emergency_alert_id === (int) $alert->id, 404);
        abort_unless($commitment->status === 'donated' && $commitment->donation_history_id !== null, 422);

        $payload = $request->validate([
            'destination_type' => ['nullable', Rule::in(['patient', 'reserve'])],
            'current_step' => ['nullable', 'string', 'max:80'],
            'location_label' => ['nullable', 'string', 'max:255'],
            'publish' => ['nullable', 'boolean'],
        ]);

        // Xác định trước giao dịch: lần cập nhật này có phải là bước hoàn tất + công bố không?
        // Nếu có, sinh lời cảm ơn AI cá nhân hóa NGOÀI transaction để không giữ khóa DB
        // trong lúc gọi HTTP tới nhà cung cấp AI. Chỉ sinh khi journey chưa hoàn tất trước đó.
        $existingJourney = $commitment->bloodJourney;
        $destinationTypePre = $payload['destination_type']
            ?? $existingJourney?->destination_type
            ?? ($alert->status === 'fulfilled' ? 'reserve' : 'patient');
        $stepKeysPre = collect(BloodJourney::defaultSteps($destinationTypePre))->pluck('step_key');
        $requestedStep = $payload['current_step'] ?? $existingJourney?->current_step ?? 'received';
        
        $hasStepChanged = ($existingJourney === null)
            || ($existingJourney->destination_type !== $destinationTypePre)
            || ($existingJourney->current_step !== $requestedStep);

        $isFinalStep = $stepKeysPre->last() === $requestedStep;
        $willComplete = ($payload['publish'] ?? false) && $isFinalStep;

        $oldFallbacks = [
            'Giọt máu quý giá của bạn đã được truyền cho bệnh nhân tại phòng cấp cứu. Cảm ơn bạn đã giành lại một mạng sống!',
            'Ca cấp cứu hiện đã ổn định nhờ sự hỗ trợ kịp thời. Đơn vị máu của bạn đã được lưu trữ an toàn tại kho máu dự trữ để sẵn sàng cứu sống những bệnh nhân tiếp theo. Cảm ơn nghĩa cử cao đẹp của bạn!'
        ];
        $isOldOrEmpty = empty($existingJourney?->final_message) || in_array($existingJourney?->final_message, $oldFallbacks);

        $aiFinalMessage = null;
        if ($willComplete && (empty($existingJourney?->completed_at) || $isOldOrEmpty)) {
            $commitment->loadMissing('donor');
            $aiFinalMessage = $this->gratitudeService->generate(
                [
                    'donor_name' => $commitment->donor?->name,
                    'blood_type' => $commitment->donor?->blood_type,
                    'hospital_name' => $alert->hospital?->name,
                    'destination_type' => $destinationTypePre,
                ],
                BloodJourney::finalMessageFor($destinationTypePre, $commitment->id),
            );
        }

        $wasAlreadyCompleted = false;
        $journey = DB::transaction(function () use ($alert, $commitment, $payload, $aiFinalMessage, $willComplete, $isFinalStep, $isOldOrEmpty, &$wasAlreadyCompleted): BloodJourney {
            $history = DonationHistory::query()->findOrFail($commitment->donation_history_id);
            $journey = $this->ensureBloodJourney($alert, $commitment->loadMissing('donor'), $history, $payload['destination_type'] ?? null);

            $wasAlreadyCompleted = !empty($journey->completed_at);

            if (($payload['destination_type'] ?? $journey->destination_type) !== $journey->destination_type) {
                $journey = $this->resetJourneySteps($journey, $payload['destination_type']);
            }

            $destinationTypeChanged = (($payload['destination_type'] ?? $journey->destination_type) !== $journey->destination_type);
            $stepKeys = collect(BloodJourney::defaultSteps($journey->destination_type))->pluck('step_key')->values();
            $stepKey = $payload['current_step'] ?? $journey->current_step;
            abort_unless($stepKeys->contains($stepKey), 422);

            if (!$destinationTypeChanged) {
                $currentIndex = $stepKeys->search($journey->current_step);
                $newIndex = $stepKeys->search($stepKey);
                abort_if($newIndex < $currentIndex, 422, 'Không thể quay ngược lại bước hành trình cũ.');
            }

            $completedStepKeys = $stepKeys->take($stepKeys->search($stepKey) + 1);

            // Ưu tiên lời cảm ơn AI vừa sinh; nếu không có, giữ nội dung đã lưu; cuối cùng rơi về mẫu tĩnh.
            $finalMessage = $aiFinalMessage
                ?? ($isOldOrEmpty ? BloodJourney::finalMessageFor($journey->destination_type, $commitment->id) : $journey->final_message);
            $journey->update([
                'current_step' => $stepKey,
                'location_label' => $payload['location_label'] ?? $journey->location_label,
                'final_message' => $finalMessage,
                'completed_at' => $isFinalStep ? ($journey->completed_at ?? now()) : null,
                'published_at' => ($payload['publish'] ?? false) ? now() : $journey->published_at,
            ]);

            $journey->steps()->whereIn('step_key', $completedStepKeys->all())->whereNull('occurred_at')->update(['occurred_at' => now()]);
            $journey->steps()->whereNotIn('step_key', $completedStepKeys->all())->update(['occurred_at' => null]);

            if ($willComplete && !$wasAlreadyCompleted) {
                $this->createMobileNotification(
                    $journey->donor_id,
                    'blood_journey_completed',
                    'Lời cảm ơn từ hành trình giọt máu',
                    $journey->final_message ?? BloodJourney::finalMessageFor($journey->destination_type, $commitment->id),
                    ['blood_journey_id' => $journey->public_id, 'destination_type' => $journey->destination_type],
                );
            }

            return $journey->refresh()->load('hospital', 'steps');
        });

        // Chỉ broadcast tới mobile khi journey đạt BƯỚC CUỐI và được công bố — đây là
        // lúc bật màn cảm ơn cho người hiến. Các bước trung gian (tiếp nhận, kiểm tra
        // chất lượng, vận chuyển...) không đẩy realtime.
        // Lưu ý: KHÔNG gate thêm "!wasAlreadyCompleted" — để việc lưu lại bước cuối vẫn
        // re-broadcast nếu mobile lỡ mất lần đầu. Notification vẫn được gate trong
        // transaction nên không tạo thông báo trùng.
        if ($willComplete) {
            $commitment->refresh()->load('donor', 'alert', 'bloodJourney.steps');
            $this->broadcastCommitment($commitment);
        }

        return BloodJourneyResource::make($journey);
    }

    public function commit(Request $request, EmergencyAlert $alert): JsonResponse
    {
        $payload = $request->validate([
            'donor_id' => ['nullable', 'integer', 'exists:users,id'],
            'latitude' => ['nullable', 'numeric'],
            'longitude' => ['nullable', 'numeric'],
            'eta_minutes' => ['nullable', 'integer', 'min:1', 'max:240'],
        ]);
        $donor = $this->mobileUserResolver->resolve(
            $payload['donor_id'] ?? $request->integer('user_id')
        );
        $hasLocation = array_key_exists('latitude', $payload) && array_key_exists('longitude', $payload);

        $commitment = EmergencyCommitment::query()
            ->where('emergency_alert_id', $alert->id)
            ->where('donor_id', $donor->id)
            ->first();

        abort_if($commitment?->status === 'donated', 409, 'Ca SOS này đã được bệnh viện ghi nhận hiến máu.');

        abort_if($alert->status === 'fulfilled', 409, 'Cảm ơn bạn, ca hiến máu này đã nhận đủ đơn vị máu cần thiết. Hệ thống đã lưu ghi nhận và xin hẹn bạn ở lượt tiếp theo nhé!');
        abort_if($alert->status !== 'active', 409, 'Ca SOS này hiện không còn nhận thêm cam kết.');

        $commitmentValues = [
            'status' => 'committed',
            'latitude' => $payload['latitude'] ?? $commitment?->latitude,
            'longitude' => $payload['longitude'] ?? $commitment?->longitude,
            'eta_minutes' => $payload['eta_minutes'] ?? $commitment?->eta_minutes,
            'committed_at' => $commitment?->committed_at ?? now(),
            'last_location_at' => $hasLocation ? now() : $commitment?->last_location_at,
        ];
        if ($this->supportsCommitmentCancelReason()) {
            $commitmentValues['cancel_reason'] = null;
        }

        $commitment = EmergencyCommitment::query()->updateOrCreate(
            [
                'emergency_alert_id' => $alert->id,
                'donor_id' => $donor->id,
            ],
            $commitmentValues,
        );

        $commitment->load('donor.province', 'donor.ward', 'alert.hospital');
        $this->broadcastCommitment($commitment);

        return EmergencyCommitmentResource::make($commitment)
            ->response()
            ->setStatusCode(200);
    }

    public function updateLocation(Request $request, EmergencyAlert $alert): JsonResponse
    {
        $payload = $request->validate([
            'donor_id' => ['nullable', 'integer', 'exists:users,id'],
            'latitude' => ['required', 'numeric'],
            'longitude' => ['required', 'numeric'],
            'eta_minutes' => ['nullable', 'integer', 'min:1', 'max:240'],
            'status' => ['nullable', 'in:committed,en_route,cancelled'],
        ]);
        $donor = $this->mobileUserResolver->resolve(
            $payload['donor_id'] ?? $request->integer('user_id')
        );

        $commitment = EmergencyCommitment::query()
            ->where('emergency_alert_id', $alert->id)
            ->where('donor_id', $donor->id)
            ->firstOrFail();

        abort_if(in_array($commitment->status, ['donated', 'cancelled', 'not_needed']), 409, 'Cam kết này đã kết thúc, bị hủy hoặc không còn hoạt động.');

        $commitment->update([
            'latitude' => $payload['latitude'],
            'longitude' => $payload['longitude'],
            'eta_minutes' => $payload['eta_minutes'] ?? $commitment->eta_minutes,
            'status' => $payload['status'] ?? $commitment->status,
            'last_location_at' => now(),
        ]);

        $this->broadcastCommitment($commitment);

        return response()->json(['data' => ['ok' => true]]);
    }

    public function cancelCommitment(Request $request, EmergencyAlert $alert): JsonResponse
    {
        $payload = $request->validate([
            'donor_id' => ['nullable', 'integer', 'exists:users,id'],
            'cancel_reason' => ['required', 'string', 'max:1000'],
        ]);
        $donor = $this->mobileUserResolver->resolve(
            $payload['donor_id'] ?? $request->integer('user_id')
        );

        $commitment = EmergencyCommitment::query()
            ->where('emergency_alert_id', $alert->id)
            ->where('donor_id', $donor->id)
            ->firstOrFail();

        abort_if($commitment->status === 'donated', 409, 'Ca SOS này đã được bệnh viện ghi nhận hiến máu.');

        $commitmentValues = [
            'status' => 'cancelled',
            'last_location_at' => now(),
        ];
        if ($this->supportsCommitmentCancelReason()) {
            $commitmentValues['cancel_reason'] = $payload['cancel_reason'];
        }

        $commitment->update($commitmentValues);

        $commitment->load('donor.province', 'donor.ward', 'alert.hospital');
        $this->broadcastCommitment($commitment);

        return EmergencyCommitmentResource::make($commitment)
            ->response()
            ->setStatusCode(200);
    }

    private function broadcastCommitment(EmergencyCommitment $commitment): void
    {
        try {
            broadcast(new EmergencyCommitmentUpdated($commitment));
        } catch (Throwable $exception) {
            Log::warning('Emergency commitment broadcast skipped.', [
                'commitment_id' => $commitment->id,
                'message' => $exception->getMessage(),
            ]);
        }
    }

    private function broadcastAlert(EmergencyAlert $alert): void
    {
        try {
            broadcast(new EmergencyAlertActivated($alert));
        } catch (Throwable $exception) {
            Log::warning('Emergency alert broadcast skipped.', [
                'alert_id' => $alert->public_id,
                'message' => $exception->getMessage(),
            ]);
        }
    }

    private function evaluateAlertFulfillment(EmergencyAlert $alert): void
    {
        $alert->refresh();
        if ($alert->status !== 'active') {
            return;
        }

        $donatedCount = $alert->commitments()->where('status', 'donated')->count();
        if ($donatedCount < $alert->units_needed) {
            return;
        }

        DB::transaction(function () use ($alert): void {
            $alert->update(['status' => 'fulfilled']);
        });

        $alert->load('hospital.province', 'hospital.ward', 'recipients.donor.province', 'commitments.donor.province', 'commitments.bloodJourney.steps');
        $this->realtimeGateway->publish($alert);
        $this->broadcastAlert($alert);
    }

    private function ensureBloodJourney(EmergencyAlert $alert, EmergencyCommitment $commitment, DonationHistory $history, ?string $destinationType = null): BloodJourney
    {
        $destinationType ??= $alert->status === 'fulfilled' ? 'reserve' : 'patient';
        $journey = BloodJourney::query()->firstOrCreate(
            ['emergency_commitment_id' => $commitment->id],
            [
                'public_id' => (string) Str::uuid(),
                'emergency_alert_id' => $alert->id,
                'donation_history_id' => $history->id,
                'donor_id' => $commitment->donor_id,
                'hospital_id' => $alert->hospital_id,
                'destination_type' => $destinationType,
                'current_step' => 'received',
                'location_label' => $alert->hospital?->name,
                'final_message' => BloodJourney::finalMessageFor($destinationType, $commitment->id),
            ],
        );

        if ($journey->wasRecentlyCreated) {
            $this->seedJourneySteps($journey);
        }

        return $journey->load('hospital', 'steps');
    }

    private function resetJourneySteps(BloodJourney $journey, string $destinationType): BloodJourney
    {
        $journey->update([
            'destination_type' => $destinationType,
            'current_step' => 'received',
            'completed_at' => null,
            'published_at' => null,
            'final_message' => BloodJourney::finalMessageFor($destinationType, $journey->emergency_commitment_id),
        ]);
        $journey->steps()->delete();
        $this->seedJourneySteps($journey);

        return $journey->refresh()->load('hospital', 'steps');
    }

    private function seedJourneySteps(BloodJourney $journey): void
    {
        foreach (BloodJourney::defaultSteps($journey->destination_type) as $index => $step) {
            $journey->steps()->create([
                ...$step,
                'sort_order' => $index + 1,
                'occurred_at' => $index === 0 ? now() : null,
            ]);
        }
    }

    private function createMobileNotification(int $userId, string $type, string $title, string $body, array $payload = []): void
    {
        $notification = MobileNotification::query()->create([
            'user_id' => $userId,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'payload' => $payload,
        ]);

        try {
            broadcast(new MobileNotificationCreated($notification));
        } catch (Throwable $exception) {
            Log::warning('Mobile notification broadcast skipped.', [
                'notification_id' => $notification->id,
                'message' => $exception->getMessage(),
            ]);
        }
    }

    private function supportsCommitmentCancelReason(): bool
    {
        return Schema::hasColumn('emergency_commitments', 'cancel_reason');
    }
}
