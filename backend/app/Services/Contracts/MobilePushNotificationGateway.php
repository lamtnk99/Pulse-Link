<?php

namespace App\Services\Contracts;

use App\Models\MobileNotification;
use App\Models\NotificationDevice;

interface MobilePushNotificationGateway
{
    /** @return array{provider_message_id: string|null, skipped?: bool} */
    public function send(NotificationDevice $device, MobileNotification $notification, bool $isSos): array;
}
