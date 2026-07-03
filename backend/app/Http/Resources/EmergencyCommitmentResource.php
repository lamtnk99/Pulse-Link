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
            'donation_volume_ml' => $this->donation_volume_ml,
            'committed_at' => $this->committed_at?->toIso8601String(),
            'last_location_at' => $this->last_location_at?->toIso8601String(),
            'donated_at' => $this->donated_at?->toIso8601String(),
            'verified_at' => $this->verified_at?->toIso8601String(),
            'verified_by' => $this->verified_by,
            'donation_history_id' => $this->donation_history_id,
            'donor' => UserDonorResource::make($this->whenLoaded('donor')),
        ];
    }
}
