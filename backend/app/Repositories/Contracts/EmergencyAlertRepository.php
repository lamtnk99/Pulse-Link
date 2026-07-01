<?php

namespace App\Repositories\Contracts;

use App\Models\EmergencyAlert;
use App\Models\Hospital;

interface EmergencyAlertRepository
{
    public function createActiveAlert(array $payload, Hospital $hospital): EmergencyAlert;

    public function cancel(EmergencyAlert $alert): EmergencyAlert;
}
