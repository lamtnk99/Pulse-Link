<?php

use App\Http\Controllers\Api\Admin\AdminDashboardController;
use App\Http\Controllers\Api\Admin\BloodStockController;
use App\Http\Controllers\Api\Admin\CampaignManagerController;
use App\Http\Controllers\Api\Admin\CommunityPostController as AdminCommunityPostController;
use App\Http\Controllers\Api\Admin\DonationEventController as AdminDonationEventController;
use App\Http\Controllers\Api\Admin\EmergencyController;
use App\Http\Controllers\Api\Admin\HospitalController as AdminHospitalController;
use App\Http\Controllers\Api\Admin\IdVerificationController;
use App\Http\Controllers\Api\Admin\SettingsController as AdminSettingsController;
use App\Http\Controllers\Api\Admin\StaffController as AdminStaffController;
use App\Http\Controllers\Api\Admin\UploadController as AdminUploadController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BloodJourneyController;
use App\Http\Controllers\Api\CertificateController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Api\Mobile\ChatController as MobileChatController;
use App\Http\Controllers\Api\Mobile\CommunityImpactController;
use App\Http\Controllers\Api\Mobile\CommunityPostController as MobileCommunityPostController;
use App\Http\Controllers\Api\Mobile\DonationController as MobileDonationFundController;
use App\Http\Controllers\Api\Mobile\MobileDonationController;
use App\Http\Controllers\Api\Mobile\MobileNotificationController;
use App\Http\Controllers\Api\Mobile\MobileProfileController;
use App\Http\Controllers\Api\Mobile\MobileUploadController;
use App\Http\Controllers\Api\Mobile\MockPaymentController;
use App\Http\Controllers\Api\Mobile\RoutePlannerController;
use Illuminate\Support\Facades\Route;

Route::post('auth/login', [AuthController::class, 'login']);
Route::post('auth/register', [AuthController::class, 'register']);
Route::middleware('auth:sanctum')->group(function () {
    Route::post('auth/logout', [AuthController::class, 'logout']);
    Route::get('auth/me', [AuthController::class, 'me']);
    Route::delete('mobile/me/account', [MobileProfileController::class, 'deleteAccount']);
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
    Route::post('uploads', [MobileUploadController::class, 'store']);
    Route::get('me/donations', [MobileDonationController::class, 'history']);
    Route::get('me/notifications', [MobileNotificationController::class, 'index']);
    Route::post('me/notifications/test', [MobileNotificationController::class, 'testPush'])
        ->middleware('throttle:3,1');
    Route::post('me/notifications/{notification}/read', [MobileNotificationController::class, 'markRead']);
    Route::get('me/notification-preferences', [MobileNotificationController::class, 'preferences']);
    Route::put('me/notification-preferences', [MobileNotificationController::class, 'updatePreferences']);
    Route::post('me/notification-devices', [MobileNotificationController::class, 'registerDevice']);
    Route::delete('me/notification-devices', [MobileNotificationController::class, 'removeDevice']);
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
    Route::get('community-impact', [CommunityImpactController::class, 'index']);
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

    // Donation Campaigns
    Route::get('donation/campaigns', [MobileDonationFundController::class, 'index']);
    Route::get('donation/campaigns/{campaign}', [MobileDonationFundController::class, 'show']);
    Route::post('donation/campaigns/{campaign}/donate-cash', [MobileDonationFundController::class, 'donateCash']);
    Route::post('donation/campaigns/{campaign}/donate-points', [MobileDonationFundController::class, 'donatePoints']);
    Route::get('donation/transactions/{transaction_id}/status', [MobileDonationFundController::class, 'checkTransactionStatus']);
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

    // Donation Campaigns Manager
    Route::apiResource('campaigns', CampaignManagerController::class)->except(['show']);
    Route::get('campaigns/{campaign}/transactions', [CampaignManagerController::class, 'transactions']);

    // Xác thực căn cước người hiến máu
    Route::get('id-verifications', [IdVerificationController::class, 'index']);
    Route::post('id-verifications/{user}/approve', [IdVerificationController::class, 'approve']);
    Route::post('id-verifications/{user}/reject', [IdVerificationController::class, 'reject']);

    // Blood Stock & AI Forecasting
    Route::get('blood-stocks', [BloodStockController::class, 'index']);
    Route::post('blood-stocks', [BloodStockController::class, 'store']);
    Route::put('blood-stocks/{id}/status', [BloodStockController::class, 'updateStatus']);
    Route::get('blood-stocks/forecast', [BloodStockController::class, 'getForecast']);
    Route::post('blood-stocks/forecast', [BloodStockController::class, 'getForecast']);
    Route::post('blood-stocks/forecast/generate', [BloodStockController::class, 'getForecast']);
    Route::get('blood-stocks/thresholds', [BloodStockController::class, 'getThresholds']);
    Route::put('blood-stocks/thresholds', [BloodStockController::class, 'updateThresholds']);
    Route::get('blood-stocks/alerts', [BloodStockController::class, 'getAlerts']);
    Route::post('blood-stocks/alerts/{id}/mobilize', [BloodStockController::class, 'mobilizeAlert']);
    Route::get('blood-stocks/reports', [BloodStockController::class, 'getReports']);
});

// Mock Payment Simulator & Webhook (Public Routes)
Route::get('mock-payment/{transaction_id}', [MockPaymentController::class, 'show'])->name('mock-payment.show');
Route::post('mock-payment/submit', [MockPaymentController::class, 'submit'])->name('mock-payment.submit');
Route::post('payment/webhook', [MobileDonationFundController::class, 'paymentWebhook'])->name('payment.webhook');
