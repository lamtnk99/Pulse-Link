<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BloodJourneyResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->public_id,
            'destination_type' => $this->destination_type,
            'current_step' => $this->current_step,
            'location_label' => $this->location_label,
            'final_message' => $this->final_message,
            'published_at' => $this->published_at?->toIso8601String(),
            'completed_at' => $this->completed_at?->toIso8601String(),
            'verify_url' => $request->getSchemeAndHttpHost().'/journeys/'.$this->public_id,
            'hospital' => [
                'name' => $this->hospital?->name,
                'address' => $this->hospital?->address,
            ],
            'steps' => $this->steps->map(fn ($step): array => [
                'key' => $step->step_key,
                'label' => $step->label,
                'message' => $step->message,
                'occurred_at' => $step->occurred_at?->toIso8601String(),
                'completed' => $step->occurred_at !== null,
            ])->values(),
        ];
    }
}
