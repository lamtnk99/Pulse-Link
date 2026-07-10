<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NotificationDelivery extends Model
{
    use HasFactory;

    protected $fillable = [
        'mobile_notification_id',
        'notification_device_id',
        'status',
        'provider_message_id',
        'failure_code',
        'failure_message',
        'sent_at',
    ];

    protected function casts(): array
    {
        return ['sent_at' => 'datetime'];
    }

    public function notification()
    {
        return $this->belongsTo(MobileNotification::class, 'mobile_notification_id');
    }

    public function device()
    {
        return $this->belongsTo(NotificationDevice::class, 'notification_device_id');
    }
}
