<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Province extends Model
{
    protected $primaryKey = 'code';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'code',
        'name',
        'name_en',
        'full_name',
        'full_name_en',
        'code_name',
        'administrative_unit_id',
        'region_code',
        'centroid_latitude',
        'centroid_longitude',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'centroid_latitude' => 'float',
            'centroid_longitude' => 'float',
            'is_active' => 'boolean',
        ];
    }

    public function wards()
    {
        return $this->hasMany(Ward::class, 'province_code', 'code');
    }

    public function aliases()
    {
        return $this->hasMany(ProvinceAlias::class, 'province_code', 'code');
    }
}
