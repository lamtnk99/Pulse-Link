<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DonationAppointmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'status' => $this->status,
            'booked_at' => $this->booked_at?->toIso8601String(),
            'event' => DonationEventDetailResource::make($this->whenLoaded('event')),
        ];
    }
}
