<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmergencyAlert extends Model
{
    use HasFactory;

    public const COMPATIBILITY_EXACT = 'exact';
    public const COMPATIBILITY_COMPATIBLE = 'compatible';

    protected $fillable = [
        'public_id',
        'hospital_id',
        'created_by',
        'required_blood_type',
        'compatibility_mode',
        'level',
        'units_needed',
        'status',
        'message',
        'expires_at',
        'broadcast_stopped_at',
        'dispatch_summary',
    ];

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'broadcast_stopped_at' => 'datetime',
            'dispatch_summary' => 'array',
        ];
    }

    public function acceptsNewCommitments(): bool
    {
        return $this->status === 'active'
            && $this->broadcast_stopped_at === null
            && $this->expires_at?->isFuture();
    }

    public function hospital()
    {
        return $this->belongsTo(Hospital::class);
    }

    public function recipients()
    {
        return $this->hasMany(EmergencyAlertRecipient::class);
    }

    public function commitments()
    {
        return $this->hasMany(EmergencyCommitment::class);
    }
}
