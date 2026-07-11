<?php

namespace App\Http\Resources;

use App\Services\Gratitude\GratitudeCardService;
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
            'final_message' => $this->completed_at ? $this->resource->resolvedFinalMessage() : null,
            // Lời cảm ơn Pulse Link được gửi ngay khi xác nhận hiến.
            // Thư từ người nhà/bệnh viện chỉ mở khi hành trình hoàn tất.
            'pulse_link_message' => $this->pulse_link_message,
            'gratitude_style' => $this->gratitude_style,
            'gratitude_card' => $this->completed_at
                ? app(GratitudeCardService::class)->journeyPayload($this->resource)
                : null,
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
