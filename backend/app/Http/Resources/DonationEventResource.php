<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DonationEventResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $userId = $request->attributes->get('mobile_user_id');
        if (! $userId && $request->query('user_id')) {
            $userId = (int) $request->query('user_id');
        }

        $distanceKm = $this->distance_km ?? null;
        $appointments = $this->relationLoaded('appointments') ? $this->appointments : collect();
        $appointment = $userId
            ? $appointments->first(
                fn ($item): bool => (int) $item->user_id === (int) $userId && $item->status !== 'cancelled'
            )
            : null;
        $booked = $appointment?->status === 'booked';

        return [
            'id' => (string) $this->id,
            'drive_type' => $this->drive_type ?? 'in_hospital',
            'title' => $this->title,
            'organizer' => $this->organizer,
            'description' => $this->description,
            'starts_at' => $this->starts_at?->toIso8601String(),
            'ends_at' => $this->ends_at?->toIso8601String(),
            'location_name' => $this->location_name,
            'province_code' => $this->province_code,
            'province' => ProvinceResource::make($this->whenLoaded('province')),
            'ward_code' => $this->ward_code,
            'ward' => WardResource::make($this->whenLoaded('ward')),
            'location' => [
                'latitude' => $this->latitude,
                'longitude' => $this->longitude,
            ],
            'distance_km' => $distanceKm === null ? 0 : round((float) $distanceKm, 2),
            'urgency' => $this->urgency,
            'image_url' => $this->image_url,
            'slots_left' => $this->slots_left,
            'booked' => $booked,
            'appointment_status' => $appointment?->status,
            'is_published' => $this->is_published,
            'cancelled_at' => $this->cancelled_at?->toIso8601String(),
            'cancel_reason' => $this->cancel_reason,
        ];
    }
}
