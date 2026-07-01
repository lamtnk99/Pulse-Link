<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Services\Mobile\MobileUserResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MobileProfileController extends Controller
{
    public function __construct(
        private readonly MobileUserResolver $mobileUserResolver,
    ) {}

    public function heroPass(Request $request): JsonResponse
    {
        $user = $this->mobileUserResolver
            ->resolve($request->integer('user_id'))
            ->load('province', 'ward');

        return response()->json([
            'data' => [
                'id' => (string) $user->id,
                'name' => $user->name,
                'blood_type' => $user->blood_type,
                'hero_level' => $user->hero_level,
                'badge_title' => $user->badge_title,
                'total_donations' => $user->total_donations,
                'last_donation_date' => $user->last_donation_date?->toIso8601String() ?? now()->subMonths(3)->toIso8601String(),
                'points' => $user->points,
                'province_code' => $user->province_code,
                'province' => $user->province ? [
                    'code' => $user->province->code,
                    'name' => $user->province->name,
                    'full_name' => $user->province->full_name,
                ] : null,
                'ward_code' => $user->ward_code,
                'ward' => $user->ward ? [
                    'code' => $user->ward->code,
                    'name' => $user->ward->name,
                    'full_name' => $user->ward->full_name,
                ] : null,
                'hero_pass_code' => 'PL-'.$user->id.'-'.strtoupper(str_replace(' ', '', $user->name)),
            ],
        ]);
    }

    public function updateHeroPass(Request $request): JsonResponse
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));
        $payload = $request->validate([
            'fcm_token' => ['nullable', 'string', 'max:512'],
            'latitude' => ['nullable', 'numeric'],
            'longitude' => ['nullable', 'numeric'],
            'province_code' => ['nullable', 'exists:provinces,code'],
            'ward_code' => ['nullable', 'exists:wards,code'],
        ]);

        $user->update([
            ...$payload,
            'last_seen_at' => now(),
        ]);

        return $this->heroPass($request);
    }
}
