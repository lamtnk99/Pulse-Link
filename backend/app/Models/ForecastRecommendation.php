<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ForecastRecommendation extends Model
{
    use HasFactory;

    protected $fillable = [
        'forecast_run_id', 'hospital_id', 'blood_type', 'action_type', 'status', 'severity',
        'title', 'rationale', 'due_date', 'projected_gap_units', 'payload', 'approved_by',
        'approved_at', 'resolution_note',
    ];

    protected function casts(): array
    {
        return [
            'due_date' => 'date',
            'projected_gap_units' => 'float',
            'payload' => 'array',
            'approved_at' => 'datetime',
        ];
    }

    public function run()
    {
        return $this->belongsTo(BloodForecastRun::class, 'forecast_run_id');
    }
}
