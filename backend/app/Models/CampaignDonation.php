<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CampaignDonation extends Model
{
    use HasFactory;

    protected $fillable = [
        'donation_campaign_id',
        'user_id',
        'amount',
        'points',
        'payment_method',
        'payment_status',
        'transaction_id',
        'donor_name',
        'message',
        'is_anonymous',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'float',
            'points' => 'integer',
            'is_anonymous' => 'boolean',
        ];
    }

    public function campaign()
    {
        return $this->belongsTo(DonationCampaign::class, 'donation_campaign_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
