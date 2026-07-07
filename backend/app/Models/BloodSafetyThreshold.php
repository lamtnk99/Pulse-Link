<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BloodSafetyThreshold extends Model
{
    use HasFactory;

    protected $fillable = [
        'hospital_id',
        'blood_type',
        'min_units',
    ];

    protected function casts(): array
    {
        return [
            'min_units' => 'integer',
        ];
    }

    public function hospital()
    {
        return $this->belongsTo(Hospital::class);
    }
}
