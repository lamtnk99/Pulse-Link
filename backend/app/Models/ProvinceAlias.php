<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProvinceAlias extends Model
{
    protected $fillable = [
        'alias',
        'normalized_alias',
        'province_code',
        'note',
    ];

    public function province()
    {
        return $this->belongsTo(Province::class, 'province_code', 'code');
    }
}
