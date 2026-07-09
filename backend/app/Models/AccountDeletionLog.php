<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AccountDeletionLog extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'user_hash',
        'email_hash',
        'role',
        'reason',
        'status',
        'deleted_at',
    ];

    protected function casts(): array
    {
        return [
            'deleted_at' => 'datetime',
        ];
    }
}
