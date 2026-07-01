<?php

namespace App\Services\Contracts;

use App\Models\EmergencyAlert;
use Illuminate\Support\Collection;

interface PushNotificationGateway
{
    public function sendEmergencyAlert(EmergencyAlert $alert, Collection $recipients): void;
}
