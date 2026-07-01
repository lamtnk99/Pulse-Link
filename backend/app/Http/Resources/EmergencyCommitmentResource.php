<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EmergencyCommitmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'alert_id' => $this->alert?->public_id,
            'status' => $this->status,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'eta_minutes' => $this->eta_minutes,
            'committed_at' => $this->committed_at?->toIso8601String(),
            'last_location_at' => $this->last_location_at?->toIso8601String(),
            'donor' => UserDonorResource::make($this->whenLoaded('donor')),
        ];
    }
}
