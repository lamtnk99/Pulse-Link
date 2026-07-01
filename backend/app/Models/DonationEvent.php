<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DonationEvent extends Model
{
    use HasFactory;

    protected $fillable = [
        'hospital_id',
        'title',
        'organizer',
        'description',
        'starts_at',
        'ends_at',
        'location_name',
        'province_code',
        'ward_code',
        'latitude',
        'longitude',
        'urgency',
        'image_url',
        'capacity',
        'booked_count',
        'is_published',
    ];

    protected function casts(): array
    {
        return [
            'starts_at' => 'datetime',
            'ends_at' => 'datetime',
            'latitude' => 'float',
            'longitude' => 'float',
            'is_published' => 'boolean',
        ];
    }

    public function hospital()
    {
        return $this->belongsTo(Hospital::class);
    }

    public function province()
    {
        return $this->belongsTo(Province::class, 'province_code', 'code');
    }

    public function ward()
    {
        return $this->belongsTo(Ward::class, 'ward_code', 'code');
    }

    public function appointments()
    {
        return $this->hasMany(DonationAppointment::class);
    }

    public function getSlotsLeftAttribute(): int
    {
        return max(0, $this->capacity - $this->booked_count);
    }
}
