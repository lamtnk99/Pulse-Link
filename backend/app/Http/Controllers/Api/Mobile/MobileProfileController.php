<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Services\Donations\DonationRecognitionService;
use App\Services\Mobile\MobileUserResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class MobileProfileController extends Controller
{
    public function __construct(
        private readonly MobileUserResolver $mobileUserResolver,
        private readonly DonationRecognitionService $recognitionService,
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
                'blood_type_verification_status' => $user->blood_type_verification_status ?? ($user->blood_type ? 'self_reported' : 'unreported'),
                'blood_type_verified_at' => $user->blood_type_verified_at?->toIso8601String(),
                'hero_level' => $user->hero_level,
                'badge_title' => $user->badge_title,
                'total_donations' => $user->total_donations,
                'last_donation_date' => $user->last_donation_date?->toIso8601String() ?? now()->subMonths(3)->toIso8601String(),
                'points' => $user->points,
                'province_code' => $user->province_code,
                'recognition' => $this->recognitionService->recognitionFor($user),
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
                'email' => $user->email,
                'phone' => $user->phone,
                'date_of_birth' => $user->date_of_birth?->toDateString(),
                'gender' => $user->gender,
                'address' => $user->address,
                'national_id' => $user->national_id,
                'id_card_front_url' => $user->id_card_front_url,
                'id_card_back_url' => $user->id_card_back_url,
                'id_verification_status' => $user->id_verification_status ?? 'unverified',
                'id_rejection_reason' => $user->id_rejection_reason,
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
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:24'],
            'blood_type' => ['nullable', 'in:O-,O+,A-,A+,B-,B+,AB-,AB+'],
            'date_of_birth' => ['nullable', 'date'],
            'gender' => ['nullable', 'in:male,female,other'],
            'address' => ['nullable', 'string', 'max:255'],
            'national_id' => ['nullable', 'string', 'size:12'],
            'id_card_front_url' => ['nullable', 'url'],
            'id_card_back_url' => ['nullable', 'url'],
        ]);

        $updates = [
            ...$payload,
            'last_seen_at' => now(),
        ];

        // Nộp đủ số CCCD + 2 ảnh → chuyển sang chờ admin duyệt căn cước.
        if (array_key_exists('blood_type', $payload)) {
            $newBloodType = $payload['blood_type'];
            $hasVerifiedBloodType = ($user->blood_type_verification_status ?? null) === 'verified';
            if ($hasVerifiedBloodType && $newBloodType !== null && $newBloodType !== $user->blood_type) {
                throw ValidationException::withMessages([
                    'blood_type' => ['Nhóm máu đã được bệnh viện xác minh và không thể tự chỉnh sửa.'],
                ]);
            }

            if ($hasVerifiedBloodType || $newBloodType === null) {
                unset($updates['blood_type']);
            } else {
                $updates['blood_type_verification_status'] = 'self_reported';
                $updates['blood_type_verified_at'] = null;
                $updates['blood_type_verified_by'] = null;
                $updates['blood_type_verified_hospital_id'] = null;
                $updates['blood_type_verified_donation_history_id'] = null;
            }
        }

        $hasFullIdSubmission = filled($payload['national_id'] ?? null)
            && filled($payload['id_card_front_url'] ?? null)
            && filled($payload['id_card_back_url'] ?? null);

        if ($hasFullIdSubmission) {
            $updates['id_verification_status'] = 'pending';
            $updates['id_rejection_reason'] = null;
            $updates['id_verified_at'] = null;
        }

        $user->update($updates);

        return $this->heroPass($request);
    }
}
