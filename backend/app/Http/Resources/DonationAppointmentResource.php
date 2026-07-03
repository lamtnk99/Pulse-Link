<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DonationAppointmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $isAdminRequest = $request->is('api/admin/*');
        $canSeeResult = $isAdminRequest || $this->result_published_at !== null;

        return [
            'id' => (string) $this->id,
            'status' => $this->status,
            'booked_at' => $this->booked_at?->toIso8601String(),
            'checked_in_at' => $this->checked_in_at?->toIso8601String(),
            'cancelled_at' => $this->cancelled_at?->toIso8601String(),
            'cancel_reason' => $this->cancel_reason,
            'completed_at' => $this->completed_at?->toIso8601String(),
            'no_show_at' => $this->no_show_at?->toIso8601String(),
            'volume_ml' => $this->volume_ml,
            'screening_status' => $this->screening_status,
            'screening_notes' => $isAdminRequest ? $this->screening_notes : null,
            'result_summary' => $canSeeResult ? $this->result_summary : null,
            'result_published_at' => $this->result_published_at?->toIso8601String(),
            'certificate' => $this->whenLoaded('donationHistory', fn () => $this->donationHistory ? [
                'id' => (string) $this->donationHistory->id,
                'certificate_id' => $this->donationHistory->certificate_id,
                'certificate_title' => $this->donationHistory->certificate_title,
                'certificate_issued_at' => $this->donationHistory->certificate_issued_at?->toIso8601String(),
                'certificate_verify_url' => $request->getSchemeAndHttpHost().'/certificates/'.$this->donationHistory->certificate_id,
                'donation_type' => $this->donationHistory->donation_type ?? 'regular',
            ] : null),
            'user' => UserDonorResource::make($this->whenLoaded('user')),
            'event' => DonationEventDetailResource::make($this->whenLoaded('event')),
        ];
    }
}
