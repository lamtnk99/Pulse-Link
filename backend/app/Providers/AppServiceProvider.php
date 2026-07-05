<?php

namespace App\Providers;

use App\Repositories\Contracts\DonorRepository;
use App\Repositories\Contracts\EmergencyAlertRepository;
use App\Repositories\Contracts\LocationRepository;
use App\Repositories\Eloquent\EloquentDonorRepository;
use App\Repositories\Eloquent\EloquentEmergencyAlertRepository;
use App\Repositories\Eloquent\EloquentLocationRepository;
use App\Services\Contracts\EmergencyAlertRealtimeGateway;
use App\Services\Contracts\PushNotificationGateway;
use App\Services\Firebase\FcmHttpV1PushNotificationGateway;
use App\Services\Firebase\FirestoreEmergencyAlertRealtimeGateway;
use Illuminate\Support\ServiceProvider;

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
        $this->app->bind(EmergencyAlertRealtimeGateway::class, FirestoreEmergencyAlertRealtimeGateway::class);
        $this->app->bind(\App\Services\Contracts\AiChatService::class, \App\Services\Chat\FallbackAiChatService::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        \App\Models\DonationAppointment::observe(\App\Observers\DonationAppointmentObserver::class);
    }
}
