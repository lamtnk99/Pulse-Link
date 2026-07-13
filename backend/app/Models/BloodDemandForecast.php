<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BloodDemandForecast extends Model
{
    use HasFactory;

    protected $fillable = [
        'forecast_run_id',
        'hospital_id',
        'forecast_date',
        'target_date',
        'blood_type',
        'predicted_units',
        'predicted_volume_ml',
        'lower_units',
        'upper_units',
        'actual_units',
        'confidence_score',
        'model_version',
        'explanation',
    ];

    protected function casts(): array
    {
        return [
            'forecast_date' => 'date',
            'target_date' => 'date',
            'predicted_units' => 'float',
            'predicted_volume_ml' => 'integer',
            'lower_units' => 'float',
            'upper_units' => 'float',
            'actual_units' => 'float',
            'confidence_score' => 'float',
        ];
    }

    public function hospital()
    {
        return $this->belongsTo(Hospital::class);
    }

    public function run()
    {
        return $this->belongsTo(BloodForecastRun::class, 'forecast_run_id');
    }
}
