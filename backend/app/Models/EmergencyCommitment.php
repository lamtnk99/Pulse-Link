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
        'donation_volume_ml',
        'committed_at',
        'last_location_at',
        'donated_at',
        'verified_at',
        'verified_by',
        'donation_history_id',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'float',
            'longitude' => 'float',
            'committed_at' => 'datetime',
            'last_location_at' => 'datetime',
            'donated_at' => 'datetime',
            'verified_at' => 'datetime',
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

    public function donationHistory()
    {
        return $this->belongsTo(DonationHistory::class);
    }

    public function verifier()
    {
        return $this->belongsTo(User::class, 'verified_by');
    }
}
