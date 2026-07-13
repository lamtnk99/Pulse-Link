<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BloodStockMovement extends Model
{
    use HasFactory;

    protected $fillable = [
        'hospital_id',
        'blood_stock_id',
        'donation_history_id',
        'blood_type',
        'movement_type',
        'from_status',
        'to_status',
        'quantity_units',
        'volume_ml',
        'available_delta',
        'actor_id',
        'source_type',
        'source_id',
        'idempotency_key',
        'is_synthetic',
        'notes',
        'metadata',
        'occurred_at',
    ];

    protected function casts(): array
    {
        return [
            'quantity_units' => 'integer',
            'volume_ml' => 'integer',
            'available_delta' => 'integer',
            'is_synthetic' => 'boolean',
            'metadata' => 'array',
            'occurred_at' => 'datetime',
        ];
    }

    public function stock()
    {
        return $this->belongsTo(BloodStock::class, 'blood_stock_id');
    }

    public function hospital()
    {
        return $this->belongsTo(Hospital::class);
    }
}
