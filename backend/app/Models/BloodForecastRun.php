<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BloodForecastRun extends Model
{
    use HasFactory;

    protected $fillable = [
        'hospital_id', 'status', 'trigger', 'model_version', 'data_start_date',
        'data_end_date', 'generated_at', 'generated_by', 'scenarios', 'data_quality',
        'metrics', 'reasoning_summary', 'recommendations', 'ai_provider', 'error_message',
    ];

    protected function casts(): array
    {
        return [
            'data_start_date' => 'date',
            'data_end_date' => 'date',
            'generated_at' => 'datetime',
            'scenarios' => 'array',
            'data_quality' => 'array',
            'metrics' => 'array',
            'recommendations' => 'array',
        ];
    }

    public function hospital()
    {
        return $this->belongsTo(Hospital::class);
    }

    public function points()
    {
        return $this->hasMany(BloodDemandForecast::class, 'forecast_run_id');
    }

    public function recommendationRecords()
    {
        return $this->hasMany(ForecastRecommendation::class, 'forecast_run_id');
    }
}
