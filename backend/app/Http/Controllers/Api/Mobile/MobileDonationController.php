<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Domain\Geo\DistanceCalculator;
use App\Domain\Geo\GeoPoint;
use App\Http\Controllers\Controller;
use App\Http\Resources\DonationAppointmentResource;
use App\Http\Resources\DonationEventDetailResource;
use App\Http\Resources\DonationEventResource;
use App\Models\DonationAppointment;
use App\Models\DonationEvent;
use App\Models\DonationHistory;
use App\Models\User;
use App\Services\Mobile\MobileUserResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MobileDonationController extends Controller
{
    public function __construct(
        private readonly DistanceCalculator $distanceCalculator,
        private readonly MobileUserResolver $mobileUserResolver,
    ) {}

    public function events(Request $request)
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));
        $request->attributes->set('mobile_user_id', $user->id);
        $origin = $this->originFromRequest($request);

        return DonationEventResource::collection(
            DonationEvent::query()
                ->with('appointments', 'province', 'ward', 'hospital.province', 'hospital.ward')
                ->where('is_published', true)
                ->where('ends_at', '>=', now())
                ->orderBy('starts_at')
                ->get()
                ->map(function (DonationEvent $event) use ($origin): DonationEvent {
                    $event->distance_km = $origin
                        ? $this->distanceCalculator->kilometers(
                            $origin,
                            new GeoPoint((float) $event->latitude, (float) $event->longitude),
                        )
                        : 0;

                    return $event;
                })
        );
    }

    public function show(Request $request, DonationEvent $event): DonationEventDetailResource
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));
        $request->attributes->set('mobile_user_id', $user->id);
        $origin = $this->originFromRequest($request);

        $event->load('appointments', 'province', 'ward', 'hospital.province', 'hospital.ward');
        $event->distance_km = $origin
            ? $this->distanceCalculator->kilometers(
                $origin,
                new GeoPoint((float) $event->latitude, (float) $event->longitude),
            )
            : 0;

        return DonationEventDetailResource::make($event);
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
                ->where('status', 'booked')
                ->whereHas('event', fn ($query) => $query->where('ends_at', '>=', now()))
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
            DonationAppointment::query()->updateOrCreate(
                ['donation_event_id' => $event->id, 'user_id' => $userId],
                ['status' => 'booked', 'booked_at' => now()]
            );

            $event->update([
                'booked_count' => $event->appointments()->where('status', 'booked')->count(),
            ]);
        });

        return DonationEventResource::make(
            $event->refresh()->load('appointments', 'province', 'ward', 'hospital.province', 'hospital.ward')
        );
    }

    public function cancel(Request $request, DonationEvent $event): DonationEventResource
    {
        $userId = $this->mobileUserResolver->resolve($request->integer('user_id'))->id;
        $request->attributes->set('mobile_user_id', $userId);

        DB::transaction(function () use ($event, $userId): void {
            DonationAppointment::query()
                ->where('donation_event_id', $event->id)
                ->where('user_id', $userId)
                ->update(['status' => 'cancelled']);

            $event->update([
                'booked_count' => $event->appointments()->where('status', 'booked')->count(),
            ]);
        });

        return DonationEventResource::make(
            $event->refresh()->load('appointments', 'province', 'ward', 'hospital.province', 'hospital.ward')
        );
    }

    public function history(Request $request): JsonResponse
    {
        $userId = $this->mobileUserResolver->resolve($request->integer('user_id'))->id;

        return response()->json([
            'data' => DonationHistory::query()
                ->where('user_id', $userId)
                ->latest('donated_at')
                ->get()
                ->map(fn (DonationHistory $history): array => [
                    'id' => (string) $history->id,
                    'donated_at' => $history->donated_at?->toIso8601String(),
                    'location_name' => $history->location_name,
                    'volume_ml' => $history->volume_ml,
                    'blood_type' => $history->blood_type,
                    'certificate_id' => $history->certificate_id,
                    'status' => $history->status,
                    'notes' => $history->notes,
                ]),
        ]);
    }

    public function storeHistory(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'user_id' => ['nullable', 'integer', 'exists:users,id'],
            'donated_at' => ['required', 'date'],
            'location_name' => ['required', 'string', 'max:255'],
            'volume_ml' => ['required', 'integer', 'min:200', 'max:500'],
            'blood_type' => ['required', 'string', 'max:4'],
            'notes' => ['nullable', 'string'],
        ]);

        $user = $this->mobileUserResolver->resolve($payload['user_id'] ?? null);
        $history = DonationHistory::create([
            ...$payload,
            'user_id' => $user->id,
            'certificate_id' => 'PL-'.now()->year.'-'.random_int(1000, 9999),
            'status' => 'verified',
        ]);

        $user->update([
            'total_donations' => $user->total_donations + 1,
            'points' => $user->points + 250,
            'last_donation_date' => $history->donated_at,
        ]);

        return response()->json(['data' => [
            'id' => (string) $history->id,
            'donated_at' => $history->donated_at?->toIso8601String(),
            'location_name' => $history->location_name,
            'volume_ml' => $history->volume_ml,
            'blood_type' => $history->blood_type,
            'certificate_id' => $history->certificate_id,
            'status' => $history->status,
            'notes' => $history->notes,
        ]]);
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
}
