<?php

namespace App\Repositories\Eloquent;

use App\Models\EmergencyAlert;
use App\Models\Hospital;
use App\Repositories\Contracts\EmergencyAlertRepository;
use Illuminate\Support\Str;

class EloquentEmergencyAlertRepository implements EmergencyAlertRepository
{
    public function createActiveAlert(array $payload, Hospital $hospital): EmergencyAlert
    {
        return EmergencyAlert::create([
            'public_id' => (string) Str::uuid(),
            'hospital_id' => $hospital->id,
            'created_by' => $payload['created_by'] ?? null,
            'required_blood_type' => $payload['required_blood_type'],
            'level' => $payload['level'],
            'units_needed' => $payload['units_needed'],
            'status' => 'active',
            'message' => $payload['message'],
            'expires_at' => $payload['expires_at'],
        ]);
    }

    public function cancel(EmergencyAlert $alert): EmergencyAlert
    {
        $alert->update(['status' => 'cancelled']);

        return $alert->refresh();
    }
}
