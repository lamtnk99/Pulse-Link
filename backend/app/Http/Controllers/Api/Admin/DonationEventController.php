<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\DonationAppointmentResource;
use App\Http\Resources\DonationEventDetailResource;
use App\Models\DonationAppointment;
use App\Models\DonationEvent;
use App\Models\DonationHistory;
use App\Models\Hospital;
use App\Services\Admin\AdminUserResolver;
use App\Services\Donations\DonationRecognitionService;
use App\Services\Donations\PostDonationCareService;
use App\Services\Inventory\BloodInventoryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class DonationEventController extends Controller
{
    public function __construct(
        private readonly AdminUserResolver $adminUserResolver,
        private readonly DonationRecognitionService $recognitionService,
        private readonly PostDonationCareService $postDonationCareService,
        private readonly BloodInventoryService $bloodInventoryService,
    ) {}

    public function index(Request $request)
    {
        $admin = $this->adminUserResolver->resolve($request);
        $perPage = min(max($request->integer('per_page', 10), 1), 50);
        $status = $request->query('status');
        $keyword = trim((string) $request->query('q', ''));
        $hospitalId = $request->integer('hospital_id') ?: null;
        $provinceCode = $request->query('province_code');
        $dateFrom = $request->date('date_from')?->startOfDay();
        $dateTo = $request->date('date_to')?->endOfDay();
        $now = now();

        if ($admin->role !== 'system_admin') {
            $hospitalId = $admin->hospital_id;
        }

        return DonationEventDetailResource::collection(
            DonationEvent::query()
                ->with('appointments.donationHistory', 'appointments.user.province', 'appointments.user.ward', 'province', 'ward', 'hospital.province', 'hospital.ward')
                ->when($hospitalId, fn ($query) => $query->where('hospital_id', $hospitalId))
                ->when($provinceCode, fn ($query) => $query->where('province_code', $provinceCode))
                ->when($dateFrom, fn ($query) => $query->where('starts_at', '>=', $dateFrom))
                ->when($dateTo, fn ($query) => $query->where('starts_at', '<=', $dateTo))
                ->when($keyword !== '', function ($query) use ($keyword): void {
                    $query->where(function ($query) use ($keyword): void {
                        $query
                            ->where('title', 'like', "%{$keyword}%")
                            ->orWhere('organizer', 'like', "%{$keyword}%")
                            ->orWhere('location_name', 'like', "%{$keyword}%");
                    });
                })
                ->when($status === 'cancelled', fn ($query) => $query->whereNotNull('cancelled_at'))
                ->when($status === 'draft', fn ($query) => $query->whereNull('cancelled_at')->where('is_published', false))
                ->when($status === 'published', fn ($query) => $query->whereNull('cancelled_at')->where('is_published', true))
                ->when($status === 'upcoming', fn ($query) => $query->whereNull('cancelled_at')->where('is_published', true)->where('starts_at', '>', $now))
                ->when($status === 'running', fn ($query) => $query->whereNull('cancelled_at')->where('is_published', true)->where('starts_at', '<=', $now)->where('ends_at', '>=', $now))
                ->when($status === 'ended', fn ($query) => $query->whereNull('cancelled_at')->where('ends_at', '<', $now))
                ->orderBy('starts_at')
                ->paginate($perPage)
        );
    }

    public function store(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'events.manage'), 403);

        $payload = $this->validatedPayload($request);
        $payload['hospital_id'] ??= $admin->hospital_id
            ?? Hospital::query()->where('is_active', true)->orderBy('id')->value('id');
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $payload['hospital_id'] ?? null), 403);

        $event = DonationEvent::query()->create([
            ...$payload,
            'booked_count' => 0,
        ]);

        return response()->json([
            'data' => DonationEventDetailResource::make(
                $event->load('appointments.donationHistory', 'province', 'ward', 'hospital.province', 'hospital.ward')
            ),
        ], 201);
    }

    public function show(Request $request, DonationEvent $event): DonationEventDetailResource
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $event->hospital_id), 403);

        return DonationEventDetailResource::make(
            $event->load([
                'appointments.donationHistory',
                'appointments.user.province',
                'appointments.user.ward',
                'province',
                'ward',
                'hospital.province',
                'hospital.ward',
            ])
        );
    }

    public function update(Request $request, DonationEvent $event): DonationEventDetailResource
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'events.manage'), 403);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $event->hospital_id), 403);

        $payload = $this->validatedPayload($request, partial: true);
        $payload = $this->sanitizeLockedFields($event, $payload);
        $this->validateCapacity($event, $payload);
        if (array_key_exists('hospital_id', $payload)) {
            abort_unless($this->adminUserResolver->canAccessHospital($admin, $payload['hospital_id']), 403);
        }

        $event->update($payload);

        return DonationEventDetailResource::make(
            $event->refresh()->load('appointments.donationHistory', 'province', 'ward', 'hospital.province', 'hospital.ward')
        );
    }

    public function destroy(Request $request, DonationEvent $event): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'events.manage'), 403);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $event->hospital_id), 403);

        $payload = $request->validate([
            'cancel_reason' => ['nullable', 'string', 'max:1000'],
        ]);

        abort_if(
            $event->appointments()->where('status', 'completed')->exists(),
            422,
            'Không thể hủy sự kiện đã có người hoàn thành hiến máu.'
        );

        DB::transaction(function () use ($event, $payload): void {
            $event->update([
                'is_published' => false,
                'cancelled_at' => now(),
                'cancel_reason' => $payload['cancel_reason'] ?? 'Sự kiện đã được hủy bởi quản trị viên.',
            ]);

            $event->appointments()
                ->where('status', '!=', 'completed')
                ->update([
                    'status' => 'cancelled',
                    'cancelled_at' => now(),
                    'cancel_reason' => $event->cancel_reason,
                ]);

            $event->refreshBookedCount();
        });

        return response()->json([
            'data' => DonationEventDetailResource::make(
                $event->refresh()->load('appointments.donationHistory', 'appointments.user.province', 'appointments.user.ward', 'province', 'ward', 'hospital.province', 'hospital.ward')
            ),
        ]);
    }

    public function checkIn(Request $request, DonationEvent $event, DonationAppointment $appointment): DonationAppointmentResource
    {
        $this->authorizeEventManagement($request, $event);
        $this->ensureAppointmentBelongsToEvent($appointment, $event);
        $this->abortIfTerminalAppointment($appointment, 'Lịch hẹn đã chốt, không thể check-in.');

        $appointment->update([
            'status' => 'checked_in',
            'checked_in_at' => $appointment->checked_in_at ?? now(),
            'no_show_at' => null,
            'screening_status' => $appointment->status === 'deferred'
                ? 'pending'
                : ($appointment->screening_status ?? 'pending'),
        ]);
        $event->refreshBookedCount();

        return $this->appointmentResource($appointment);
    }

    public function cancelAppointment(Request $request, DonationEvent $event, DonationAppointment $appointment): DonationAppointmentResource
    {
        $this->authorizeEventManagement($request, $event);
        $this->ensureAppointmentBelongsToEvent($appointment, $event);
        $this->abortIfTerminalAppointment($appointment, 'Không thể hủy lịch đã hoàn thành hoặc đã hủy.');
        $payload = $request->validate([
            'cancel_reason' => ['nullable', 'string', 'max:1000'],
        ]);

        $appointment->update([
            'status' => 'cancelled',
            'cancelled_at' => now(),
            'cancel_reason' => $payload['cancel_reason'] ?? 'Lịch hẹn đã được hủy bởi quản trị viên.',
        ]);
        $event->refreshBookedCount();

        return $this->appointmentResource($appointment);
    }

    public function noShow(Request $request, DonationEvent $event, DonationAppointment $appointment): DonationAppointmentResource
    {
        $this->authorizeEventManagement($request, $event);
        $this->ensureAppointmentBelongsToEvent($appointment, $event);
        $this->abortIfTerminalAppointment($appointment, 'Không thể đổi lịch đã chốt sang không đến.');

        $appointment->update([
            'status' => 'no_show',
            'no_show_at' => now(),
            'screening_status' => $appointment->screening_status === 'ineligible'
                ? null
                : $appointment->screening_status,
        ]);
        $event->refreshBookedCount();

        return $this->appointmentResource($appointment);
    }

    public function defer(Request $request, DonationEvent $event, DonationAppointment $appointment): DonationAppointmentResource
    {
        $this->authorizeEventManagement($request, $event);
        $this->ensureAppointmentBelongsToEvent($appointment, $event);
        $this->abortIfTerminalAppointment($appointment, 'Không thể tạm hoãn lịch đã chốt.');
        $payload = $request->validate([
            'screening_notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $appointment->update([
            'status' => 'deferred',
            'checked_in_at' => $appointment->checked_in_at ?? now(),
            'no_show_at' => null,
            'screening_status' => 'ineligible',
            'screening_notes' => $payload['screening_notes'] ?? $appointment->screening_notes,
        ]);
        $event->refreshBookedCount();

        return $this->appointmentResource($appointment);
    }

    public function completeAppointment(Request $request, DonationEvent $event, DonationAppointment $appointment): DonationAppointmentResource
    {
        $this->authorizeEventManagement($request, $event);
        $this->ensureAppointmentBelongsToEvent($appointment, $event);
        abort_unless(
            in_array($appointment->status, ['booked', 'checked_in', 'deferred', 'no_show'], true),
            422,
            'Chỉ có thể hoàn thành lịch chưa chốt.'
        );

        $payload = $request->validate([
            'volume_ml' => ['required', 'integer', Rule::in([250, 350, 450])],
            'blood_type' => ['required', Rule::in(['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'])],
            'screening_status' => ['nullable', Rule::in(['pending', 'eligible', 'ineligible'])],
            'screening_notes' => ['nullable', 'string', 'max:1000'],
            'result_summary' => ['nullable', 'string', 'max:2000'],
            'publish_result' => ['sometimes', 'boolean'],
        ]);

        $admin = $this->adminUserResolver->resolve($request);
        $appointment->load('event.hospital', 'user');
        $alreadyCompleted = $appointment->status === 'completed'
            || DonationHistory::query()->where('donation_appointment_id', $appointment->id)->exists();
        $hasPublishResult = array_key_exists('publish_result', $payload);
        $publishResult = (bool) ($payload['publish_result'] ?? false);

        DB::transaction(function () use ($appointment, $event, $payload, $alreadyCompleted, $hasPublishResult, $publishResult, $admin): void {
            $appointment->update([
                'status' => 'completed',
                'checked_in_at' => $appointment->checked_in_at ?? now(),
                'completed_at' => $appointment->completed_at ?? now(),
                'no_show_at' => null,
                'volume_ml' => $payload['volume_ml'],
                'screening_status' => $payload['screening_status'] ?? 'eligible',
                'screening_notes' => $payload['screening_notes'] ?? $appointment->screening_notes,
                'result_summary' => $payload['result_summary'] ?? $appointment->result_summary,
                'result_published_at' => $hasPublishResult
                    ? ($publishResult ? ($appointment->result_published_at ?? now()) : null)
                    : $appointment->result_published_at,
            ]);

            $history = DonationHistory::query()->updateOrCreate(
                ['donation_appointment_id' => $appointment->id],
                $this->recognitionService->prepareCertificateAttributes([
                    'user_id' => $appointment->user_id,
                    'hospital_id' => $event->hospital_id,
                    'donation_type' => 'regular',
                    'donated_at' => ($appointment->completed_at ?? now())->toDateString(),
                    'location_name' => $event->location_name,
                    'volume_ml' => $payload['volume_ml'],
                    'blood_type' => $payload['blood_type'],
                    'certificate_id' => 'PL-EVENT-'.$event->id.'-'.$appointment->id,
                    'certificate_title' => 'Chứng nhận hiến máu tại '.$event->title,
                    'status' => 'verified',
                    'notes' => $payload['result_summary'] ?? $payload['screening_notes'] ?? 'Ghi nhận từ lịch hiến máu '.$event->title,
                ]),
            );

            // Lịch hiến thường chỉ được hoàn tất sau khi nhân viên xác nhận,
            // vì vậy đơn vị máu có thể vào kho khả dụng ngay.
            $this->bloodInventoryService->receiveDonation(
                history: $history,
                hospitalId: $event->hospital_id,
                initialStatus: BloodInventoryService::STATUS_AVAILABLE,
                movementType: 'regular_donation_received',
                sourceType: 'donation_appointment',
                sourceId: $appointment->id,
                actorId: $admin->id,
                notes: 'Hiến máu tình nguyện từ sự kiện: ' . $event->title,
            );

            $appointment->user->update([
                'blood_type' => $payload['blood_type'],
                'blood_type_verification_status' => 'verified',
                'blood_type_verified_at' => now(),
                'blood_type_verified_by' => $admin->id,
                'blood_type_verified_hospital_id' => $event->hospital_id,
                'blood_type_verified_donation_history_id' => $history->id,
            ]);

            if (! $alreadyCompleted) {
                $this->recognitionService->awardNewDonation(
                    $appointment->user,
                    'regular',
                    $appointment->completed_at ?? now(),
                );
                $this->postDonationCareService->createForDonation($history);
            }

            $event->refreshBookedCount();
        });

        return $this->appointmentResource($appointment);
    }

    public function publishResult(Request $request, DonationEvent $event, DonationAppointment $appointment): DonationAppointmentResource
    {
        $this->authorizeEventManagement($request, $event);
        $this->ensureAppointmentBelongsToEvent($appointment, $event);
        abort_unless($appointment->status === 'completed', 422, 'Chỉ công bố kết quả cho lịch đã hoàn thành.');
        $payload = $request->validate([
            'result_summary' => ['nullable', 'string', 'max:2000'],
            'publish_result' => ['sometimes', 'boolean'],
        ]);

        $appointment->update([
            'result_summary' => array_key_exists('result_summary', $payload)
                ? $payload['result_summary']
                : $appointment->result_summary,
            'result_published_at' => (bool) ($payload['publish_result'] ?? true) ? now() : null,
        ]);

        return $this->appointmentResource($appointment);
    }

    private function validatedPayload(Request $request, bool $partial = false): array
    {
        $prefix = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'hospital_id' => ['nullable', 'integer', 'exists:hospitals,id'],
            'drive_type' => ['sometimes', 'in:in_hospital,mobile'],
            'title' => [$prefix, 'string', 'max:255'],
            'organizer' => [$prefix, 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'starts_at' => [$prefix, 'date'],
            'ends_at' => [$prefix, 'date', 'after:starts_at'],
            'location_name' => [$prefix, 'string', 'max:255'],
            'province_code' => [$prefix, 'string', 'size:2', 'exists:provinces,code'],
            'ward_code' => ['nullable', 'string', 'size:5', 'exists:wards,code'],
            'latitude' => [$prefix, 'numeric', 'between:-90,90'],
            'longitude' => [$prefix, 'numeric', 'between:-180,180'],
            'urgency' => ['sometimes', 'in:normal,high'],
            'image_url' => ['nullable', 'string', 'max:2048'],
            'capacity' => ['sometimes', 'integer', 'min:1', 'max:5000'],
            'is_published' => ['sometimes', 'boolean'],
        ]);
    }

    private function sanitizeLockedFields(DonationEvent $event, array $payload): array
    {
        if ($event->booked_count <= 0) {
            return $payload;
        }

        return collect($payload)
            ->except([
                'starts_at',
                'ends_at',
                'location_name',
                'province_code',
                'ward_code',
                'latitude',
                'longitude',
                'hospital_id',
            ])
            ->all();
    }

    private function validateCapacity(DonationEvent $event, array $payload): void
    {
        if (! array_key_exists('capacity', $payload)) {
            return;
        }

        if ((int) $payload['capacity'] < (int) $event->booked_count) {
            throw ValidationException::withMessages([
                'capacity' => 'Chỉ tiêu tiếp nhận không được nhỏ hơn số người đã đặt lịch.',
            ]);
        }
    }

    private function authorizeEventManagement(Request $request, DonationEvent $event): void
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'events.manage'), 403);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $event->hospital_id), 403);
    }

    private function ensureAppointmentBelongsToEvent(DonationAppointment $appointment, DonationEvent $event): void
    {
        abort_unless((int) $appointment->donation_event_id === (int) $event->id, 404);
    }

    private function abortIfTerminalAppointment(DonationAppointment $appointment, string $message): void
    {
        abort_if(in_array($appointment->status, ['cancelled', 'completed'], true), 422, $message);
    }

    private function appointmentResource(DonationAppointment $appointment): DonationAppointmentResource
    {
        return DonationAppointmentResource::make(
            $appointment->refresh()->load('donationHistory', 'user.province', 'user.ward', 'event.province', 'event.ward', 'event.hospital.province', 'event.hospital.ward')
        );
    }
}
