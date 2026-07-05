<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class DonationCampaign extends Model
{
    use HasFactory;

    protected $fillable = [
        'public_id',
        'title',
        'description',
        'image_url',
        'type',
        'target_amount',
        'current_amount',
        'target_points',
        'current_points',
        'status',
        'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'target_amount' => 'float',
            'current_amount' => 'float',
            'target_points' => 'integer',
            'current_points' => 'integer',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (DonationCampaign $campaign): void {
            $campaign->public_id ??= (string) Str::uuid();
        });
    }

    public function donations()
    {
        return $this->hasMany(CampaignDonation::class);
    }
}
