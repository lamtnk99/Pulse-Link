<?php

namespace App\Providers;

use App\Events\MobileNotificationCreated;
use App\Jobs\DispatchMobilePushNotification;
use App\Models\DonationAppointment;
use App\Observers\DonationAppointmentObserver;
use App\Repositories\Contracts\DonorRepository;
use App\Repositories\Contracts\EmergencyAlertRepository;
use App\Repositories\Contracts\LocationRepository;
use App\Repositories\Eloquent\EloquentDonorRepository;
use App\Repositories\Eloquent\EloquentEmergencyAlertRepository;
use App\Repositories\Eloquent\EloquentLocationRepository;
use App\Services\Chat\FallbackAiChatService;
use App\Services\Contracts\AiChatService;
use App\Services\Contracts\EmergencyAlertRealtimeGateway;
use App\Services\Contracts\MobilePushNotificationGateway;
use App\Services\Contracts\PushNotificationGateway;
use App\Services\Firebase\FcmHttpV1PushNotificationGateway;
use App\Services\Firebase\FirestoreEmergencyAlertRealtimeGateway;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\ServiceProvider;
use Throwable;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(DonorRepository::class, EloquentDonorRepository::class);
        $this->app->bind(EmergencyAlertRepository::class, EloquentEmergencyAlertRepository::class);
        $this->app->bind(LocationRepository::class, EloquentLocationRepository::class);
        $this->app->bind(PushNotificationGateway::class, FcmHttpV1PushNotificationGateway::class);
        $this->app->bind(MobilePushNotificationGateway::class, FcmHttpV1PushNotificationGateway::class);
        $this->app->bind(EmergencyAlertRealtimeGateway::class, FirestoreEmergencyAlertRealtimeGateway::class);
        $this->app->bind(AiChatService::class, FallbackAiChatService::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        DonationAppointment::observe(DonationAppointmentObserver::class);
        Event::listen(MobileNotificationCreated::class, function (MobileNotificationCreated $event): void {
            try {
                DispatchMobilePushNotification::dispatch($event->notification->id)->afterCommit();
            } catch (Throwable $exception) {
                // FCM chạy qua queue riêng; lỗi enqueue không được phép chặn
                // broadcast Reverb vốn đang phục vụ các luồng realtime hiện có.
                Log::error('Could not enqueue Firebase push notification.', [
                    'notification_id' => $event->notification->id,
                    'message' => $exception->getMessage(),
                ]);
            }
        });
    }
}
