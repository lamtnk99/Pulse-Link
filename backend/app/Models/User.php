<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'phone',
        'role',
        'hospital_id',
        'permissions',
        'blood_type',
        'hero_level',
        'badge_title',
        'total_donations',
        'points',
        'last_donation_date',
        'province_code',
        'ward_code',
        'latitude',
        'longitude',
        'fcm_token',
        'last_seen_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'permissions' => 'array',
            'last_donation_date' => 'date',
            'latitude' => 'float',
            'longitude' => 'float',
            'last_seen_at' => 'datetime',
        ];
    }

    public function commitments()
    {
        return $this->hasMany(EmergencyCommitment::class, 'donor_id');
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
}
