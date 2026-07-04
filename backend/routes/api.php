<?php

use App\Http\Controllers\Api\Admin\AdminDashboardController;
use App\Http\Controllers\Api\Admin\CommunityPostController as AdminCommunityPostController;
use App\Http\Controllers\Api\Admin\DonationEventController as AdminDonationEventController;
use App\Http\Controllers\Api\Admin\EmergencyController;
use App\Http\Controllers\Api\Admin\HospitalController as AdminHospitalController;
use App\Http\Controllers\Api\Admin\StaffController as AdminStaffController;
use App\Http\Controllers\Api\Admin\UploadController as AdminUploadController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BloodJourneyController;
use App\Http\Controllers\Api\CertificateController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Api\Mobile\CommunityPostController as MobileCommunityPostController;
use App\Http\Controllers\Api\Mobile\MobileDonationController;
use App\Http\Controllers\Api\Mobile\MobileNotificationController;
use App\Http\Controllers\Api\Mobile\MobileProfileController;
use App\Http\Controllers\Api\Mobile\RoutePlannerController;
use App\Http\Controllers\Api\Mobile\ChatController as MobileChatController;
use App\Http\Controllers\Api\Admin\SettingsController as AdminSettingsController;
use Illuminate\Support\Facades\Route;

Route::post('auth/login', [AuthController::class, 'login']);
Route::middleware('auth:sanctum')->group(function () {
    Route::post('auth/logout', [AuthController::class, 'logout']);
    Route::get('auth/me', [AuthController::class, 'me']);
});

Route::prefix('locations')->group(function () {
    Route::get('provinces', [LocationController::class, 'provinces']);
    Route::get('provinces/{province:code}/wards', [LocationController::class, 'wards']);
    Route::post('normalize', [LocationController::class, 'normalize']);
});

Route::get('certificates/{certificateId}', [CertificateController::class, 'show']);
Route::get('blood-journeys/{publicId}', [BloodJourneyController::class, 'show']);

Route::prefix('mobile')->middleware(['role:donor'])->group(function () {
    Route::get('me/hero-pass', [MobileProfileController::class, 'heroPass']);
    Route::post('me/hero-pass', [MobileProfileController::class, 'updateHeroPass']);
    Route::get('me/donations', [MobileDonationController::class, 'history']);
    Route::get('me/notifications', [MobileNotificationController::class, 'index']);
    Route::post('me/notifications/{notification}/read', [MobileNotificationController::class, 'markRead']);
    Route::get('me/appointments', [MobileDonationController::class, 'appointments']);
    Route::get('me/sos-commitment', [EmergencyController::class, 'mobileActiveCommitment']);
    Route::get('realtime-config', [EmergencyController::class, 'mobileRealtimeConfig']);
    Route::post('me/donations', [MobileDonationController::class, 'storeHistory']);
    Route::get('donation-events', [MobileDonationController::class, 'events']);
    Route::get('donation-events/{event}', [MobileDonationController::class, 'show']);
    Route::post('donation-events/{event}/book', [MobileDonationController::class, 'book']);
    Route::post('donation-events/{event}/cancel', [MobileDonationController::class, 'cancel']);
    Route::get('community-posts', [MobileCommunityPostController::class, 'index']);
    Route::get('community-posts/{post:slug}', [MobileCommunityPostController::class, 'show']);
    Route::post('routes/plan', [RoutePlannerController::class, 'plan']);
    Route::get('sos-alerts', [EmergencyController::class, 'mobileIndex']);
    Route::post('sos-alerts/{alert:public_id}/commit', [EmergencyController::class, 'commit']);
    Route::post('sos-alerts/{alert:public_id}/location', [EmergencyController::class, 'updateLocation']);
    Route::post('sos-alerts/{alert:public_id}/cancel', [EmergencyController::class, 'cancelCommitment']);

    // Chatbot AI
    Route::get('me/chats', [MobileChatController::class, 'index']);
    Route::post('me/chats', [MobileChatController::class, 'store']);
    Route::get('me/chats/active-checkup', [MobileChatController::class, 'activeCheckup']);
    Route::get('me/chats/quota', [MobileChatController::class, 'quota']);
    Route::get('me/chats/{chat}', [MobileChatController::class, 'show']);
    Route::post('me/chats/{chat}/messages', [MobileChatController::class, 'sendMessage']);
});

Route::prefix('admin')->middleware(['role:admin'])->group(function () {
    Route::get('dashboard', [AdminDashboardController::class, 'show']);
    Route::post('uploads', [AdminUploadController::class, 'store']);
    Route::apiResource('hospitals', AdminHospitalController::class)->except(['show']);
    Route::apiResource('donation-events', AdminDonationEventController::class)
        ->parameters(['donation-events' => 'event']);
    Route::post('donation-events/{event}/appointments/{appointment}/check-in', [AdminDonationEventController::class, 'checkIn']);
    Route::post('donation-events/{event}/appointments/{appointment}/cancel', [AdminDonationEventController::class, 'cancelAppointment']);
    Route::post('donation-events/{event}/appointments/{appointment}/no-show', [AdminDonationEventController::class, 'noShow']);
    Route::post('donation-events/{event}/appointments/{appointment}/defer', [AdminDonationEventController::class, 'defer']);
    Route::post('donation-events/{event}/appointments/{appointment}/complete', [AdminDonationEventController::class, 'completeAppointment']);
    Route::post('donation-events/{event}/appointments/{appointment}/publish-result', [AdminDonationEventController::class, 'publishResult']);
    Route::apiResource('community-posts', AdminCommunityPostController::class)
        ->parameters(['community-posts' => 'post'])
        ->except(['show']);
    Route::apiResource('staff', AdminStaffController::class)->except(['show']);
    Route::post('emergency-alerts', [EmergencyController::class, 'store']);
    Route::get('emergency-alerts/{alert:public_id}', [EmergencyController::class, 'show']);
    Route::post('emergency-alerts/{alert:public_id}/cancel', [EmergencyController::class, 'cancel']);
    Route::post('emergency-alerts/{alert:public_id}/complete', [EmergencyController::class, 'complete']);
    Route::post('emergency-alerts/{alert:public_id}/commitments/{commitment}/donated', [EmergencyController::class, 'markCommitmentDonated']);
    Route::post('emergency-alerts/{alert:public_id}/commitments/{commitment}/journey', [EmergencyController::class, 'updateCommitmentJourney']);

    // AI Settings
    Route::get('settings', [AdminSettingsController::class, 'index']);
    Route::put('settings', [AdminSettingsController::class, 'update']);
    Route::post('settings/test-ai', [AdminSettingsController::class, 'testProvider']);
});
