<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NotificationPreference extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'sos_enabled',
        'appointments_enabled',
        'care_enabled',
        'nearby_events_enabled',
        'community_enabled',
        'quiet_hours_start',
        'quiet_hours_end',
    ];

    protected function casts(): array
    {
        return [
            'sos_enabled' => 'boolean',
            'appointments_enabled' => 'boolean',
            'care_enabled' => 'boolean',
            'nearby_events_enabled' => 'boolean',
            'community_enabled' => 'boolean',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
