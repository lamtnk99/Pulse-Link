<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmergencyAlert extends Model
{
    use HasFactory;

    protected $fillable = [
        'public_id',
        'hospital_id',
        'created_by',
        'required_blood_type',
        'level',
        'units_needed',
        'status',
        'message',
        'expires_at',
        'dispatch_summary',
    ];

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'dispatch_summary' => 'array',
        ];
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
