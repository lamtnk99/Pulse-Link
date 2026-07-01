<?php

namespace App\Services\Mobile;

use App\Models\User;

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
            ->firstOrFail();
    }
}
