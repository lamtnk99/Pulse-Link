<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ChatConversation extends Model
{
    use HasFactory;

    public const CONTEXT_GENERAL = 'general';
    public const CONTEXT_PRE_DONATION_GUIDANCE = 'pre_donation_guidance';
    public const CONTEXT_APPOINTMENT_REMINDER = 'appointment_reminder';
    public const CONTEXT_POST_DONATION_CHECKUP = 'post_donation_checkup';
    public const CONTEXT_DONATION_DEFERRED = 'donation_deferred';

    protected $fillable = [
        'user_id',
        'title',
        'context_type',
        'context_meta',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'context_meta' => 'array',
            'is_active' => 'boolean',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function messages()
    {
        return $this->hasMany(ChatMessage::class);
    }

    public function latestMessage()
    {
        return $this->hasOne(ChatMessage::class)->latestOfMany();
    }
}
