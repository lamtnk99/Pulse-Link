<?php

namespace App\Repositories\Eloquent;

use App\Models\User;
use App\Repositories\Contracts\DonorRepository;
use Illuminate\Support\Collection;

class EloquentDonorRepository implements DonorRepository
{
    public function compatibleActiveDonors(array $bloodTypes): Collection
    {
        return User::query()
            ->where('role', 'donor')
            ->whereIn('blood_type', $bloodTypes)
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->whereNotNull('fcm_token')
            ->get();
    }
}
