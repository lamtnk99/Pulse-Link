<?php

use App\Http\Controllers\Api\BloodJourneyController;
use App\Http\Controllers\Api\CertificateController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('certificates/{certificateId}', [CertificateController::class, 'page']);
Route::get('journeys/{publicId}', [BloodJourneyController::class, 'page']);
