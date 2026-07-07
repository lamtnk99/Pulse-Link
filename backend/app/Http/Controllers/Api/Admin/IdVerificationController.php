<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class IdVerificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $status = $request->query('status', 'pending');

        $query = User::query()
            ->where('role', 'donor')
            ->whereNotNull('national_id');

        if ($status !== 'all') {
            $query->where('id_verification_status', $status);
        }

        $users = $query
            ->orderByRaw("CASE WHEN id_verification_status = 'pending' THEN 0 ELSE 1 END")
            ->orderByDesc('updated_at')
            ->get()
            ->map(fn (User $user) => $this->format($user));

        return response()->json(['data' => $users]);
    }

    public function approve(Request $request, User $user): JsonResponse
    {
        $user->update([
            'id_verification_status' => 'verified',
            'id_verified_at' => now(),
            'id_rejection_reason' => null,
        ]);

        return response()->json([
            'message' => 'Đã xác thực căn cước thành công.',
            'data' => $this->format($user),
        ]);
    }

    public function reject(Request $request, User $user): JsonResponse
    {
        $payload = $request->validate([
            'reason' => ['required', 'string', 'max:255'],
        ]);

        $user->update([
            'id_verification_status' => 'rejected',
            'id_verified_at' => null,
            'id_rejection_reason' => $payload['reason'],
        ]);

        return response()->json([
            'message' => 'Đã từ chối hồ sơ căn cước.',
            'data' => $this->format($user),
        ]);
    }

    private function format(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'blood_type' => $user->blood_type,
            'date_of_birth' => $user->date_of_birth?->toDateString(),
            'gender' => $user->gender,
            'address' => $user->address,
            'national_id' => $user->national_id,
            'id_card_front_url' => $user->id_card_front_url,
            'id_card_back_url' => $user->id_card_back_url,
            'id_verification_status' => $user->id_verification_status ?? 'unverified',
            'id_verified_at' => $user->id_verified_at?->toIso8601String(),
            'id_rejection_reason' => $user->id_rejection_reason,
            'created_at' => $user->created_at?->toIso8601String(),
        ];
    }
}
