<?php

namespace App\Http\Controllers\Api\Admin;

use App\Domain\Blood\BloodCompatibility;
use App\Events\EmergencyAlertActivated;
use App\Events\EmergencyCommitmentUpdated;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreEmergencyAlertRequest;
use App\Http\Resources\EmergencyAlertResource;
use App\Http\Resources\EmergencyCommitmentResource;
use App\Models\DonationHistory;
use App\Models\EmergencyAlert;
use App\Models\EmergencyCommitment;
use App\Models\Hospital;
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
            $alert->load('hospital.province', 'hospital.ward', 'recipients.donor.province', 'commitments.donor.province')
        );
    }

    public function cancel(EmergencyAlert $alert): EmergencyAlertResource
    {
        $admin = $this->adminUserResolver->resolve(request());
        abort_unless($this->adminUserResolver->hasPermission($admin, 'sos.activate'), 403);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $alert->hospital_id), 403);

        $alert->update(['status' => 'cancelled']);
        $alert->load('hospital.province', 'hospital.ward', 'recipients.donor.province', 'commitments.donor.province');
        $this->realtimeGateway->publish($alert);
        $this->broadcastAlert($alert);

        return EmergencyAlertResource::make($alert->refresh()->load('hospital.province', 'hospital.ward', 'recipients.donor.province', 'commitments.donor.province'));
    }

    public function complete(Request $request, EmergencyAlert $alert): EmergencyAlertResource
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'sos.activate'), 403);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $alert->hospital_id), 403);

        $alert->update(['status' => 'fulfilled']);
        $alert->load('hospital.province', 'hospital.ward', 'recipients.donor.province', 'commitments.donor.province');
        $this->realtimeGateway->publish($alert);
        $this->broadcastAlert($alert);

        return EmergencyAlertResource::make($alert->refresh()->load('hospital.province', 'hospital.ward', 'recipients.donor.province', 'commitments.donor.province'));
    }

    public function mobileIndex(Request $request): JsonResponse
    {
        $donor = $this->mobileUserResolver->resolve($request->integer('user_id'));

        $alerts = EmergencyAlert::query()
            ->with('hospital.province', 'hospital.ward')
            ->where('expires_at', '>', now())
            ->whereIn('status', ['active', 'cancelled', 'fulfilled'])
            ->latest()
            ->limit(20)
            ->get()
            ->filter(fn (EmergencyAlert $alert): bool => $this->bloodCompatibility->canDonateTo(
                $donor->blood_type,
                $alert->required_blood_type,
            ))
            ->values();

        return response()->json([
            'data' => EmergencyAlertResource::collection($alerts)->resolve(),
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
        $alreadyDonated = $commitment->status === 'donated' || $commitment->donation_history_id !== null;

        $commitment = DB::transaction(function () use ($alert, $admin, $commitment, $donatedAt, $volumeMl, $payload, $alreadyDonated): EmergencyCommitment {
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

            return $commitment->refresh()->load('donor.province', 'donor.ward', 'alert.hospital');
        });

        $this->broadcastCommitment($commitment);

        return EmergencyCommitmentResource::make($commitment);
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

        $commitment = EmergencyCommitment::query()->updateOrCreate(
            [
                'emergency_alert_id' => $alert->id,
                'donor_id' => $donor->id,
            ],
            [
                'status' => 'committed',
                'latitude' => $payload['latitude'] ?? null,
                'longitude' => $payload['longitude'] ?? null,
                'eta_minutes' => $payload['eta_minutes'] ?? null,
                'committed_at' => now(),
                'last_location_at' => now(),
            ],
        );

        $this->broadcastCommitment($commitment);

        return response()->json([
            'data' => [
                'id' => $commitment->id,
                'status' => $commitment->status,
            ],
        ]);
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
}
