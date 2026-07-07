<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BloodStock extends Model
{
    use HasFactory;

    protected $fillable = [
        'hospital_id',
        'blood_type',
        'volume_ml',
        'received_date',
        'expiry_date',
        'status',
        'donation_history_id',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'received_date' => 'date',
            'expiry_date' => 'date',
            'volume_ml' => 'integer',
        ];
    }

    public function hospital()
    {
        return $this->belongsTo(Hospital::class);
    }

    public function donationHistory()
    {
        return $this->belongsTo(DonationHistory::class);
    }

    // Scopes
    public function scopeAvailable($query)
    {
        return $query->where('status', 'available');
    }

    public function scopeExpired($query)
    {
        return $query->where('status', 'expired')
            ->orWhere(function ($q) {
                $q->where('status', 'available')
                  ->where('expiry_date', '<', now()->toDateString());
            });
    }

    public function scopeExpiringSoon($query, $days = 7)
    {
        return $query->where('status', 'available')
            ->whereBetween('expiry_date', [
                now()->toDateString(),
                now()->addDays($days)->toDateString()
            ]);
    }
}
