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
    ];

    protected function casts(): array
    {
        return [
            'booked_at' => 'datetime',
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
}
