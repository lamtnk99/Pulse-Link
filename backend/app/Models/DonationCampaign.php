<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class DonationCampaign extends Model
{
    use HasFactory;

    /**
     * Tỉ giá quy đổi điểm Hero sang tiền: 1 điểm = 250 VND.
     * Mọi khoản góp (tiền mặt hay điểm) đều gộp vào cùng một trục tiền.
     */
    public const POINT_VALUE_VND = 250;

    protected $fillable = [
        'public_id',
        'title',
        'description',
        'image_url',
        'target_amount',
        'current_amount',
        'status',
        'beneficiary_name',
        'beneficiary_story',
        'impact_unit',
        'impact_per_unit_amount',
        'impact_per_unit_points',
        'urgency_level',
        'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'target_amount' => 'float',
            'current_amount' => 'float',
            'impact_per_unit_amount' => 'float',
            'impact_per_unit_points' => 'integer',
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
