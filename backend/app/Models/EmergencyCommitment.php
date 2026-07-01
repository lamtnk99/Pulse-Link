<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmergencyCommitment extends Model
{
    use HasFactory;

    protected $fillable = [
        'emergency_alert_id',
        'donor_id',
        'status',
        'latitude',
        'longitude',
        'eta_minutes',
        'committed_at',
        'last_location_at',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'float',
            'longitude' => 'float',
            'committed_at' => 'datetime',
            'last_location_at' => 'datetime',
        ];
    }

    public function donor()
    {
        return $this->belongsTo(User::class, 'donor_id');
    }

    public function alert()
    {
        return $this->belongsTo(EmergencyAlert::class, 'emergency_alert_id');
    }
}
