<?php

namespace App\Services\Mobile;

use App\Models\User;
use Illuminate\Support\Facades\Hash;

class MobileUserResolver
{
    public function resolve(?int $requestedUserId = null): User
    {
        if ($requestedUserId) {
            $requestedUser = User::query()
                ->where('role', 'donor')
                ->find($requestedUserId);

            if ($requestedUser) {
                return $requestedUser;
            }
        }

        return User::query()
            ->where('role', 'donor')
            ->orderBy('id')
            ->first()
            ?? $this->createFallbackDonor();
    }

    private function createFallbackDonor(): User
    {
        return User::query()->create([
            'name' => 'Người hiến máu Pulse Link',
            'email' => 'mobile.demo@pulselink.test',
            'password' => Hash::make('password'),
            'phone' => '0900000000',
            'role' => 'donor',
            'blood_type' => 'O+',
            'hero_level' => 'Bronze Badge',
            'badge_title' => 'Hiệp Sĩ Đồng',
            'total_donations' => 1,
            'points' => 250,
            'last_donation_date' => now()->subDays(100)->toDateString(),
            'province_code' => '79',
            'ward_code' => '27301',
            'latitude' => 10.7565,
            'longitude' => 106.6594,
            'last_seen_at' => now(),
        ]);
    }
}
