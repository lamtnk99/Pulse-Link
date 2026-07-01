<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmergencyAlertRecipient extends Model
{
    use HasFactory;

    protected $fillable = [
        'emergency_alert_id',
        'user_id',
        'wave',
        'distance_km',
        'notified_at',
        'acknowledged_at',
    ];

    protected function casts(): array
    {
        return [
            'distance_km' => 'float',
            'notified_at' => 'datetime',
            'acknowledged_at' => 'datetime',
        ];
    }

    public function donor()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
