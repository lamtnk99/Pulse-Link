<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class DonationHistory extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'donation_appointment_id',
        'hospital_id',
        'donation_type',
        'donated_at',
        'location_name',
        'volume_ml',
        'blood_type',
        'certificate_id',
        'certificate_title',
        'certificate_issued_at',
        'certificate_verify_token',
        'status',
        'notes',
        'gratitude_message',
        'gratitude_style',
        'gratitude_created_at',
    ];

    protected function casts(): array
    {
        return [
            'donated_at' => 'date',
            'certificate_issued_at' => 'datetime',
            'gratitude_created_at' => 'datetime',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (DonationHistory $history): void {
            $history->donation_type ??= 'regular';
            $history->certificate_title ??= match ($history->donation_type) {
                'sos' => 'Chứng nhận hiến máu khẩn cấp SOS',
                'manual' => 'Chứng nhận ghi nhận hiến máu',
                default => 'Chứng nhận hiến máu tình nguyện',
            };
            $history->certificate_issued_at ??= now();
            $history->certificate_verify_token ??= Str::upper(Str::random(16));
        });
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function appointment()
    {
        return $this->belongsTo(DonationAppointment::class, 'donation_appointment_id');
    }

    public function hospital()
    {
        return $this->belongsTo(Hospital::class);
    }

    public function bloodJourney()
    {
        return $this->hasOne(BloodJourney::class);
    }
}
