<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdministrativeUnit extends Model
{
    public $incrementing = false;

    protected $fillable = [
        'id',
        'short_name',
        'full_name',
        'short_name_en',
        'full_name_en',
    ];
}
