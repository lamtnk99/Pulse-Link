<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EmergencyAlertResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->public_id,
            'database_id' => $this->id,
            'required_blood_type' => $this->required_blood_type,
            'level' => $this->level,
            'units_needed' => $this->units_needed,
            'status' => $this->status,
            'message' => $this->message,
            'expires_at' => $this->expires_at?->toIso8601String(),
            'dispatch_summary' => $this->dispatch_summary ?? [],
            'hospital' => HospitalResource::make($this->whenLoaded('hospital')),
            'recipients' => EmergencyRecipientResource::collection($this->whenLoaded('recipients')),
            'commitments' => EmergencyCommitmentResource::collection($this->whenLoaded('commitments')),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
