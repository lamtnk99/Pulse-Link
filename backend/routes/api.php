<?php

use App\Http\Controllers\Api\Admin\AdminDashboardController;
use App\Http\Controllers\Api\Admin\CommunityPostController as AdminCommunityPostController;
use App\Http\Controllers\Api\Admin\DonationEventController as AdminDonationEventController;
use App\Http\Controllers\Api\Admin\EmergencyController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Api\Mobile\CommunityPostController as MobileCommunityPostController;
use App\Http\Controllers\Api\Mobile\MobileDonationController;
use App\Http\Controllers\Api\Mobile\MobileProfileController;
use App\Http\Controllers\Api\Mobile\RoutePlannerController;
use Illuminate\Support\Facades\Route;

Route::prefix('locations')->group(function () {
    Route::get('provinces', [LocationController::class, 'provinces']);
    Route::get('provinces/{province:code}/wards', [LocationController::class, 'wards']);
    Route::post('normalize', [LocationController::class, 'normalize']);
});

Route::prefix('mobile')->group(function () {
    Route::get('me/hero-pass', [MobileProfileController::class, 'heroPass']);
    Route::post('me/hero-pass', [MobileProfileController::class, 'updateHeroPass']);
    Route::get('me/donations', [MobileDonationController::class, 'history']);
    Route::get('me/appointments', [MobileDonationController::class, 'appointments']);
    Route::post('me/donations', [MobileDonationController::class, 'storeHistory']);
    Route::get('donation-events', [MobileDonationController::class, 'events']);
    Route::get('donation-events/{event}', [MobileDonationController::class, 'show']);
    Route::post('donation-events/{event}/book', [MobileDonationController::class, 'book']);
    Route::post('donation-events/{event}/cancel', [MobileDonationController::class, 'cancel']);
    Route::get('community-posts', [MobileCommunityPostController::class, 'index']);
    Route::get('community-posts/{post:slug}', [MobileCommunityPostController::class, 'show']);
    Route::post('routes/plan', [RoutePlannerController::class, 'plan']);
    Route::post('sos-alerts/{alert:public_id}/commit', [EmergencyController::class, 'commit']);
    Route::post('sos-alerts/{alert:public_id}/location', [EmergencyController::class, 'updateLocation']);
});

Route::prefix('admin')->group(function () {
    Route::get('dashboard', [AdminDashboardController::class, 'show']);
    Route::apiResource('donation-events', AdminDonationEventController::class)->except(['show']);
    Route::apiResource('community-posts', AdminCommunityPostController::class)->except(['show']);
    Route::post('emergency-alerts', [EmergencyController::class, 'store']);
    Route::get('emergency-alerts/{alert:public_id}', [EmergencyController::class, 'show']);
    Route::post('emergency-alerts/{alert:public_id}/cancel', [EmergencyController::class, 'cancel']);
});
