<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BloodDemandForecast extends Model
{
    use HasFactory;

    protected $fillable = [
        'hospital_id',
        'forecast_date',
        'target_date',
        'blood_type',
        'predicted_volume_ml',
        'confidence_score',
        'explanation',
    ];

    protected function casts(): array
    {
        return [
            'forecast_date' => 'date',
            'target_date' => 'date',
            'predicted_volume_ml' => 'integer',
            'confidence_score' => 'float',
        ];
    }

    public function hospital()
    {
        return $this->belongsTo(Hospital::class);
    }
}
