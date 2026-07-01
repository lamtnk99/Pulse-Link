<?php

namespace App\Events;

use App\Http\Resources\EmergencyAlertResource;
use App\Models\EmergencyAlert;
use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class EmergencyAlertActivated implements ShouldBroadcastNow
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(public EmergencyAlert $alert)
    {
        $this->alert->loadMissing('hospital', 'recipients.donor');
    }

    public function broadcastOn(): array
    {
        return [
            new Channel('hospital.'.$this->alert->hospital_id),
            new Channel('emergency-alert.'.$this->alert->public_id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'emergency.alert.activated';
    }

    public function broadcastWith(): array
    {
        return [
            'alert' => EmergencyAlertResource::make($this->alert)->resolve(),
        ];
    }
}
