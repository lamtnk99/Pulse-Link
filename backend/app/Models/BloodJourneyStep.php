<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BloodJourneyStep extends Model
{
    use HasFactory;

    protected $fillable = [
        'blood_journey_id',
        'step_key',
        'label',
        'message',
        'sort_order',
        'occurred_at',
    ];

    protected function casts(): array
    {
        return [
            'occurred_at' => 'datetime',
        ];
    }

    public function journey()
    {
        return $this->belongsTo(BloodJourney::class, 'blood_journey_id');
    }
}
