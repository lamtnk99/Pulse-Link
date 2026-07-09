<?php

use App\Http\Controllers\Api\BloodJourneyController;
use App\Http\Controllers\Api\CertificateController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::view('legal/privacy', 'legal.privacy')->name('legal.privacy');
Route::view('legal/terms', 'legal.terms')->name('legal.terms');
Route::view('legal/delete-account', 'legal.delete-account')->name('legal.delete-account');
Route::view('support', 'legal.support')->name('support');

Route::get('certificates/{certificateId}', [CertificateController::class, 'page']);
Route::get('journeys/{publicId}', [BloodJourneyController::class, 'page']);
