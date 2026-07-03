<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('hospital.{hospitalId}', fn () => true);
Broadcast::channel('emergency-alert.{publicId}', fn () => true);
Broadcast::channel('mobile.emergency-alerts', fn () => true);
Broadcast::channel('mobile.donor.{donorId}', fn () => true);
