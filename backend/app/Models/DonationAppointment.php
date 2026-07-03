<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DonationAppointment extends Model
{
    use HasFactory;

    protected $fillable = [
        'donation_event_id',
        'user_id',
        'status',
        'booked_at',
        'checked_in_at',
        'cancelled_at',
        'cancel_reason',
        'completed_at',
        'no_show_at',
        'volume_ml',
        'screening_status',
        'screening_notes',
        'result_summary',
        'result_published_at',
    ];

    protected function casts(): array
    {
        return [
            'booked_at' => 'datetime',
            'checked_in_at' => 'datetime',
            'cancelled_at' => 'datetime',
            'completed_at' => 'datetime',
            'no_show_at' => 'datetime',
            'result_published_at' => 'datetime',
        ];
    }

    public function event()
    {
        return $this->belongsTo(DonationEvent::class, 'donation_event_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function donationHistory()
    {
        return $this->hasOne(DonationHistory::class);
    }
}
