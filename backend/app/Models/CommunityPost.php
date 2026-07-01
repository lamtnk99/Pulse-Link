<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CommunityPost extends Model
{
    use HasFactory;

    protected $fillable = [
        'hospital_id',
        'author_id',
        'title',
        'slug',
        'excerpt',
        'content',
        'image_url',
        'status',
        'published_at',
        'audience_type',
        'target_blood_type',
        'target_hero_level',
        'province_code',
        'ward_code',
        'views_count',
        'shares_count',
    ];

    protected function casts(): array
    {
        return [
            'published_at' => 'datetime',
        ];
    }

    public function hospital()
    {
        return $this->belongsTo(Hospital::class);
    }

    public function author()
    {
        return $this->belongsTo(User::class, 'author_id');
    }

    public function province()
    {
        return $this->belongsTo(Province::class, 'province_code', 'code');
    }

    public function ward()
    {
        return $this->belongsTo(Ward::class, 'ward_code', 'code');
    }
}
