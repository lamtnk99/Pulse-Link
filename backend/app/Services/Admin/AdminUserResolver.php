<?php

namespace App\Services\Admin;

use App\Models\User;
use Illuminate\Http\Request;

class AdminUserResolver
{
    public function resolve(Request $request): User
    {
        $requestedId = $request->integer('admin_user_id')
            ?: (int) $request->header('X-Admin-User-Id');

        if ($requestedId) {
            $requestedUser = User::query()
                ->whereIn('role', ['system_admin', 'hospital_admin', 'hospital_staff'])
                ->find($requestedId);

            if ($requestedUser) {
                return $requestedUser;
            }
        }

        $authenticatedUser = $request->user();
        if ($authenticatedUser && in_array($authenticatedUser->role, ['system_admin', 'hospital_admin', 'hospital_staff'], true)) {
            return $authenticatedUser;
        }

        return User::query()
            ->where('role', 'system_admin')
            ->orderBy('id')
            ->first()
            ?? User::query()
                ->whereIn('role', ['hospital_admin', 'hospital_staff'])
                ->orderBy('id')
                ->firstOrFail();
    }

    public function canAccessHospital(User $admin, ?int $hospitalId): bool
    {
        if ($admin->role === 'system_admin') {
            return true;
        }

        return $hospitalId !== null && (int) $admin->hospital_id === (int) $hospitalId;
    }

    public function hasPermission(User $admin, string $permission): bool
    {
        if ($admin->role === 'system_admin') {
            return true;
        }

        return in_array($permission, $admin->permissions ?? [], true);
    }
}
