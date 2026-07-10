<?php

namespace App\Jobs;

use App\Models\MobileNotification;
use App\Services\Mobile\MobilePushNotificationDispatcher;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class DispatchMobilePushNotification implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public bool $afterCommit = true;

    public function __construct(public readonly int $notificationId) {}

    public function handle(MobilePushNotificationDispatcher $dispatcher): void
    {
        $notification = MobileNotification::query()->find($this->notificationId);
        if ($notification !== null) {
            $dispatcher->dispatch($notification);
        }
    }
}
