<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote')->hourly();

\Illuminate\Support\Facades\Schedule::command('app:send-post-donation-checkup')->hourly();
\Illuminate\Support\Facades\Schedule::command('app:send-appointment-reminder')->dailyAt('07:00');
\Illuminate\Support\Facades\Schedule::command('blood-stock:check-expiry')->dailyAt('01:30');
\Illuminate\Support\Facades\Schedule::command('blood-forecast:generate')->dailyAt('02:00');
