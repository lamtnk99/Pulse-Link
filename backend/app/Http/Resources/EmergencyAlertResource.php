<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Http\Resources\MissingValue;

class EmergencyAlertResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $hospital = $this->whenLoaded('hospital');
        $hospitalResource = $hospital instanceof MissingValue ? null : $hospital;
        $currentCommitment = $this->resource->relationLoaded('currentCommitment')
            ? $this->resource->getRelation('currentCommitment')
            : null;

        return [
            'id' => $this->public_id,
            'database_id' => $this->id,
            'required_blood_type' => $this->required_blood_type,
            'level' => $this->level,
            'units_needed' => $this->units_needed,
            'status' => $this->status,
            'active' => $this->status === 'active',
            'message' => $this->message,
            'expires_at' => $this->expires_at?->toIso8601String(),
            'dispatch_summary' => $this->dispatch_summary ?? [],
            'hospital_name' => $hospitalResource?->name,
            'hospital_address' => $hospitalResource?->address,
            'hospital_contact_phone' => $hospitalResource?->contact_phone,
            'hospital_province_code' => $hospitalResource?->province_code,
            'hospital_location' => $hospitalResource ? [
                'latitude' => $hospitalResource->latitude,
                'longitude' => $hospitalResource->longitude,
            ] : null,
            'hospital' => HospitalResource::make($this->whenLoaded('hospital')),
            'recipients' => EmergencyRecipientResource::collection($this->whenLoaded('recipients')),
            'commitments' => EmergencyCommitmentResource::collection($this->whenLoaded('commitments')),
            'current_commitment' => $currentCommitment
                ? EmergencyCommitmentResource::make($currentCommitment)
                : null,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
