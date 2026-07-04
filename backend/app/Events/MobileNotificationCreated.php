<?php

namespace App\Events;

use App\Http\Resources\MobileNotificationResource;
use App\Models\MobileNotification;
use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MobileNotificationCreated implements ShouldBroadcastNow
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(public MobileNotification $notification) {}

    public function broadcastOn(): array
    {
        return [
            new Channel('mobile.donor.'.$this->notification->user_id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'mobile.notification.created';
    }

    public function broadcastWith(): array
    {
        return [
            'notification' => MobileNotificationResource::make($this->notification)->resolve(),
        ];
    }
}
