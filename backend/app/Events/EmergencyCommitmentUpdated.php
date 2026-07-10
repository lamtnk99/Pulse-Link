<?php

namespace App\Events;

use App\Models\EmergencyCommitment;
use App\Services\Gratitude\GratitudeCardService;
use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class EmergencyCommitmentUpdated implements ShouldBroadcastNow
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(public EmergencyCommitment $commitment)
    {
        $this->commitment->loadMissing('donor', 'alert', 'bloodJourney.steps');
    }

    public function broadcastOn(): array
    {
        return [
            new Channel('mobile.donor.'.$this->commitment->donor_id),
            new Channel('hospital.'.$this->commitment->alert->hospital_id),
            new Channel('emergency-alert.'.$this->commitment->alert->public_id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'emergency.commitment.updated';
    }

    public function broadcastWith(): array
    {
        $journey = $this->commitment->bloodJourney;

        return [
            'commitment' => [
                'id' => $this->commitment->id,
                'alert_id' => $this->commitment->alert->public_id,
                'status' => $this->commitment->status,
                'cancel_reason' => $this->commitment->cancel_reason,
                'eta_minutes' => $this->commitment->eta_minutes,
                'donation_volume_ml' => $this->commitment->donation_volume_ml,
                'latitude' => $this->commitment->latitude,
                'longitude' => $this->commitment->longitude,
                'committed_at' => $this->commitment->committed_at?->toIso8601String(),
                'last_location_at' => $this->commitment->last_location_at?->toIso8601String(),
                'donated_at' => $this->commitment->donated_at?->toIso8601String(),
                'verified_at' => $this->commitment->verified_at?->toIso8601String(),
                'verified_by' => $this->commitment->verified_by,
                'donation_history_id' => $this->commitment->donation_history_id,
                'blood_journey' => $journey ? [
                    'id' => $journey->public_id,
                    'current_step' => $journey->current_step,
                    'location_label' => $journey->location_label,
                    'destination_type' => $journey->destination_type,
                    'final_message' => $journey->completed_at ? $journey->final_message : null,
                    'pulse_link_message' => $journey->pulse_link_message,
                    'gratitude_style' => $journey->gratitude_style,
                    'gratitude_card' => $journey->completed_at
                        ? app(GratitudeCardService::class)->journeyPayload($journey)
                        : null,
                    'completed_at' => $journey->completed_at?->toIso8601String(),
                    'published_at' => $journey->published_at?->toIso8601String(),
                    'steps' => $journey->steps->map(fn ($step) => [
                        'key' => $step->step_key,
                        'label' => $step->label,
                        'completed' => $step->occurred_at !== null,
                        'occurred_at' => $step->occurred_at?->toIso8601String(),
                    ])->all(),
                ] : null,
                'donor' => [
                    'id' => $this->commitment->donor->id,
                    'name' => $this->commitment->donor->name,
                    'phone' => $this->commitment->donor->phone,
                    'blood_type' => $this->commitment->donor->blood_type,
                    'hero_level' => $this->commitment->donor->hero_level,
                    'province_code' => $this->commitment->donor->province_code,
                ],
            ],
        ];
    }
}
