<?php

namespace App\Events;

use App\Models\EmergencyCommitment;
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
        $this->commitment->loadMissing('donor', 'alert');
    }

    public function broadcastOn(): array
    {
        return [
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
        return [
            'commitment' => [
                'id' => $this->commitment->id,
                'alert_id' => $this->commitment->alert->public_id,
                'status' => $this->commitment->status,
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
                'donor' => [
                    'id' => $this->commitment->donor->id,
                    'name' => $this->commitment->donor->name,
                    'blood_type' => $this->commitment->donor->blood_type,
                    'hero_level' => $this->commitment->donor->hero_level,
                ],
            ],
        ];
    }
}
