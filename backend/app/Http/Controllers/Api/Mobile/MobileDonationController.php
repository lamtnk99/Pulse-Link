<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Domain\Geo\DistanceCalculator;
use App\Domain\Geo\GeoPoint;
use App\Http\Controllers\Controller;
use App\Http\Resources\BloodJourneyResource;
use App\Http\Resources\DonationAppointmentResource;
use App\Http\Resources\DonationEventDetailResource;
use App\Http\Resources\DonationEventResource;
use App\Models\DonationAppointment;
use App\Models\DonationEvent;
use App\Models\DonationHistory;
use App\Models\User;
use App\Services\Donations\DonationRecognitionService;
use App\Services\Mobile\MobileUserResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class MobileDonationController extends Controller
{
    public function __construct(
        private readonly DistanceCalculator $distanceCalculator,
        private readonly MobileUserResolver $mobileUserResolver,
        private readonly DonationRecognitionService $recognitionService,
    ) {}

    public function events(Request $request)
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));
        $request->attributes->set('mobile_user_id', $user->id);
        $origin = $this->originFromRequest($request);

        $events = DonationEvent::query()
            ->with('appointments', 'province', 'ward', 'hospital.province', 'hospital.ward')
            ->where('is_published', true)
            ->whereNull('cancelled_at')
            ->where('ends_at', '>=', now())
            ->orderBy('starts_at')
            ->get()
            ->map(fn (DonationEvent $event): DonationEvent => $this->withDistance($event, $origin));

        if ($origin) {
            $events = $events->sortBy('distance_km')->values();
        }

        return DonationEventResource::collection($events);
    }

    public function show(Request $request, DonationEvent $event): DonationEventDetailResource
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));
        $request->attributes->set('mobile_user_id', $user->id);
        $origin = $this->originFromRequest($request);

        $event->load('appointments', 'province', 'ward', 'hospital.province', 'hospital.ward');
        abort_if($event->cancelled_at !== null, 404);

        return DonationEventDetailResource::make($this->withDistance($event, $origin));
    }

    public function appointments(Request $request)
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));
        $request->attributes->set('mobile_user_id', $user->id);

        return DonationAppointmentResource::collection(
            DonationAppointment::query()
                ->with([
                    'event.appointments',
                    'event.province',
                    'event.ward',
                    'event.hospital.province',
                    'event.hospital.ward',
                ])
                ->where('user_id', $user->id)
                ->whereIn('status', ['booked', 'checked_in', 'deferred', 'no_show'])
                ->whereHas('event', fn ($query) => $query->whereNull('cancelled_at')->where('ends_at', '>=', now()))
                ->join('donation_events', 'donation_events.id', '=', 'donation_appointments.donation_event_id')
                ->orderBy('donation_events.starts_at')
                ->select('donation_appointments.*')
                ->get()
        );
    }

    public function book(Request $request, DonationEvent $event): DonationEventResource
    {
        $userId = $this->mobileUserResolver->resolve($request->integer('user_id'))->id;
        $request->attributes->set('mobile_user_id', $userId);

        DB::transaction(function () use ($event, $userId): void {
            $event->refresh();
            abort_if($event->cancelled_at !== null || ! $event->is_published || $event->ends_at->isPast(), 422, 'Lịch hiến máu không còn nhận đăng ký.');
            abort_if($event->slots_left <= 0, 422, 'Lịch hiến máu đã hết chỗ.');

            DonationAppointment::query()->updateOrCreate(
                ['donation_event_id' => $event->id, 'user_id' => $userId],
                [
                    'status' => 'booked',
                    'booked_at' => now(),
                    'checked_in_at' => null,
                    'cancelled_at' => null,
                    'cancel_reason' => null,
                    'completed_at' => null,
                    'no_show_at' => null,
                    'volume_ml' => null,
                    'screening_status' => null,
                    'screening_notes' => null,
                    'result_summary' => null,
                    'result_published_at' => null,
                ]
            );

            $event->refreshBookedCount();
        });

        $origin = $this->originFromRequest($request);

        return DonationEventResource::make($this->withDistance(
            $event->refresh()->load('appointments', 'province', 'ward', 'hospital.province', 'hospital.ward'),
            $origin,
        ));
    }

    public function cancel(Request $request, DonationEvent $event): DonationEventResource
    {
        $userId = $this->mobileUserResolver->resolve($request->integer('user_id'))->id;
        $request->attributes->set('mobile_user_id', $userId);

        DB::transaction(function () use ($event, $userId): void {
            $appointment = DonationAppointment::query()
                ->where('donation_event_id', $event->id)
                ->where('user_id', $userId)
                ->firstOrFail();

            abort_unless($appointment->status === 'booked', 422, 'Chỉ có thể hủy lịch đang chờ tham gia.');

            $appointment->update([
                'status' => 'cancelled',
                'cancelled_at' => now(),
                'cancel_reason' => 'Người hiến máu tự hủy lịch trên ứng dụng.',
            ]);

            $event->refreshBookedCount();
        });

        $origin = $this->originFromRequest($request);

        return DonationEventResource::make($this->withDistance(
            $event->refresh()->load('appointments', 'province', 'ward', 'hospital.province', 'hospital.ward'),
            $origin,
        ));
    }

    public function history(Request $request): JsonResponse
    {
        $userId = $this->mobileUserResolver->resolve($request->integer('user_id'))->id;

        return response()->json([
            'data' => DonationHistory::query()
                ->with('appointment', 'hospital', 'bloodJourney.hospital', 'bloodJourney.steps')
                ->where('user_id', $userId)
                ->orderByDesc('donated_at')
                ->orderByDesc('certificate_issued_at')
                ->orderByDesc('id')
                ->get()
                ->map(fn (DonationHistory $history): array => $this->historyPayload($history, $request)),
        ]);
    }

    public function storeHistory(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'user_id' => ['nullable', 'integer', 'exists:users,id'],
            'donated_at' => ['required', 'date'],
            'location_name' => ['required', 'string', 'max:255'],
            'volume_ml' => ['required', 'integer', Rule::in([250, 350, 450])],
            'blood_type' => ['required', 'string', 'max:4'],
            'notes' => ['nullable', 'string'],
        ]);

        $user = $this->mobileUserResolver->resolve($payload['user_id'] ?? null);
        $history = DonationHistory::create($this->recognitionService->prepareCertificateAttributes([
            ...$payload,
            'user_id' => $user->id,
            'donation_type' => 'manual',
            'certificate_id' => 'PL-'.now()->year.'-'.random_int(1000, 9999),
            'certificate_title' => 'Chứng nhận ghi nhận hiến máu',
            'status' => 'verified',
        ]));

        $this->recognitionService->awardNewDonation($user, 'manual', $history->donated_at);

        return response()->json(['data' => $this->historyPayload($history, $request)]);
    }

    private function originFromRequest(Request $request): ?GeoPoint
    {
        $latitude = $request->query('latitude');
        $longitude = $request->query('longitude');

        if (is_numeric($latitude) && is_numeric($longitude)) {
            return new GeoPoint((float) $latitude, (float) $longitude);
        }

        $user = User::query()->find(
            $this->mobileUserResolver->resolve($request->integer('user_id'))->id
        );
        if (! $user || $user->latitude === null || $user->longitude === null) {
            return null;
        }

        return new GeoPoint((float) $user->latitude, (float) $user->longitude);
    }

    private function withDistance(DonationEvent $event, ?GeoPoint $origin): DonationEvent
    {
        $event->distance_km = $origin
            ? $this->distanceCalculator->kilometers(
                $origin,
                new GeoPoint((float) $event->latitude, (float) $event->longitude),
            )
            : 0;

        return $event;
    }

    private function historyPayload(DonationHistory $history, Request $request): array
    {
        $history->loadMissing('appointment');

        return [
            'id' => (string) $history->id,
            'donated_at' => $history->donated_at?->toIso8601String(),
            'location_name' => $history->location_name,
            'volume_ml' => $history->volume_ml,
            'blood_type' => $history->blood_type,
            'donation_type' => $history->donation_type ?? 'regular',
            'certificate_id' => $history->certificate_id,
            'certificate_title' => $history->certificate_title,
            'certificate_issued_at' => $history->certificate_issued_at?->toIso8601String(),
            'certificate_verify_url' => $request->getSchemeAndHttpHost().'/certificates/'.$history->certificate_id,
            'blood_journey' => $history->bloodJourney
                ? BloodJourneyResource::make($history->bloodJourney)->resolve()
                : null,
            'status' => $history->status,
            'notes' => $history->notes,
            'gratitude_message' => $history->gratitude_message,
            'gratitude_style' => $history->gratitude_style,
            'gratitude_created_at' => $history->gratitude_created_at?->toIso8601String(),
            'result_summary' => $history->appointment?->result_published_at ? $history->appointment->result_summary : null,
            'result_published_at' => $history->appointment?->result_published_at?->toIso8601String(),
        ];
    }
}
