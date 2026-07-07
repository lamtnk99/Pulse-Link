<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SmartAlert extends Model
{
    use HasFactory;

    protected $fillable = [
        'hospital_id',
        'blood_type',
        'current_units',
        'threshold_units',
        'status', // active, resolved, mobilized
        'triggered_at',
        'resolved_at',
    ];

    protected function casts(): array
    {
        return [
            'current_units' => 'integer',
            'threshold_units' => 'integer',
            'triggered_at' => 'datetime',
            'resolved_at' => 'datetime',
        ];
    }

    public function hospital()
    {
        return $this->belongsTo(Hospital::class);
    }
}
