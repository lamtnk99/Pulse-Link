<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DonationHistory extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'hospital_id',
        'donated_at',
        'location_name',
        'volume_ml',
        'blood_type',
        'certificate_id',
        'status',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'donated_at' => 'date',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
