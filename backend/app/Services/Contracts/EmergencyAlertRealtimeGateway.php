<?php

namespace App\Services\Contracts;

use App\Models\EmergencyAlert;

interface EmergencyAlertRealtimeGateway
{
    public function publish(EmergencyAlert $alert): void;
}
