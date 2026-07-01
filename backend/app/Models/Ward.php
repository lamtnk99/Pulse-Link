<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Ward extends Model
{
    protected $primaryKey = 'code';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'code',
        'province_code',
        'name',
        'name_en',
        'full_name',
        'full_name_en',
        'code_name',
        'administrative_unit_id',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    public function province()
    {
        return $this->belongsTo(Province::class, 'province_code', 'code');
    }
}
