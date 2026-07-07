<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::query()
            ->where('email', $request->email)
            ->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Thông tin đăng nhập không chính xác.'],
            ]);
        }

        $token = $user->createToken('auth-token')->plainTextToken;

        return response()->json([
            'data' => [
                'token' => $token,
                'user' => [
                    'id' => (string) $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'hospital_id' => $user->hospital_id ? (string) $user->hospital_id : null,
                    'permissions' => $user->permissions ?? [],
                    'blood_type' => $user->blood_type,
                ],
            ],
        ]);
    }

    public function register(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6', 'confirmed'],
            'phone' => ['nullable', 'string', 'max:24'],
            'blood_type' => ['nullable', 'in:O-,O+,A-,A+,B-,B+,AB-,AB+'],
            'province_code' => ['nullable', 'exists:provinces,code'],
            'ward_code' => ['nullable', 'exists:wards,code'],
        ]);

        $user = User::query()->create([
            'name' => $payload['name'],
            'email' => $payload['email'],
            'password' => Hash::make($payload['password']),
            'phone' => $payload['phone'] ?? null,
            'role' => 'donor',
            'blood_type' => $payload['blood_type'] ?? null,
            'hero_level' => 'Bronze Badge',
            'badge_title' => 'Hiệp Sĩ Đồng',
            'total_donations' => 0,
            'points' => 0,
            'province_code' => $payload['province_code'] ?? null,
            'ward_code' => $payload['ward_code'] ?? null,
            'id_verification_status' => 'unverified',
            'last_seen_at' => now(),
        ]);

        $token = $user->createToken('auth-token')->plainTextToken;

        return response()->json([
            'data' => [
                'token' => $token,
                'user' => [
                    'id' => (string) $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'hospital_id' => null,
                    'permissions' => [],
                    'blood_type' => $user->blood_type,
                ],
            ],
        ], 201);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Đăng xuất thành công.',
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'data' => [
                'id' => (string) $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'hospital_id' => $user->hospital_id ? (string) $user->hospital_id : null,
                'permissions' => $user->permissions ?? [],
                'blood_type' => $user->blood_type,
            ],
        ]);
    }
}
