<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;

class DonationEventDetailResource extends DonationEventResource
{
    public function toArray(Request $request): array
    {
        $appointments = $this->relationLoaded('appointments') ? $this->appointments : collect();
        $isAdminRequest = $request->is('api/admin/*');

        return [
            ...parent::toArray($request),
            'capacity' => $this->capacity,
            'booked_count' => $this->booked_count,
            'hospital' => HospitalResource::make($this->whenLoaded('hospital')),
            'appointment_stats' => $isAdminRequest ? [
                'booked' => $appointments->where('status', 'booked')->count(),
                'checked_in' => $appointments->where('status', 'checked_in')->count(),
                'deferred' => $appointments->where('status', 'deferred')->count(),
                'no_show' => $appointments->where('status', 'no_show')->count(),
                'completed' => $appointments->where('status', 'completed')->count(),
                'cancelled' => $appointments->where('status', 'cancelled')->count(),
                'total_volume_ml' => (int) $appointments->where('status', 'completed')->sum('volume_ml'),
            ] : null,
            'appointments' => $isAdminRequest
                ? DonationAppointmentResource::collection($this->whenLoaded('appointments'))
                : null,
        ];
    }
}
