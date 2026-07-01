<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EmergencyRecipientResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'wave' => $this->wave,
            'distance_km' => $this->distance_km,
            'notified_at' => $this->notified_at?->toIso8601String(),
            'acknowledged_at' => $this->acknowledged_at?->toIso8601String(),
            'donor' => UserDonorResource::make($this->whenLoaded('donor')),
        ];
    }
}
