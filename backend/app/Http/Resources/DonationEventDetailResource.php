<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;

class DonationEventDetailResource extends DonationEventResource
{
    public function toArray(Request $request): array
    {
        return [
            ...parent::toArray($request),
            'capacity' => $this->capacity,
            'booked_count' => $this->booked_count,
            'hospital' => HospitalResource::make($this->whenLoaded('hospital')),
        ];
    }
}
