<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_login_with_valid_credentials()
    {
        $user = User::factory()->create([
            'email' => 'donor@test.com',
            'password' => Hash::make('password123'),
            'role' => 'donor',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'donor@test.com',
            'password' => 'password123',
        ]);

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'token',
                    'user' => [
                        'id',
                        'name',
                        'email',
                        'role',
                    ],
                ],
            ]);

        $this->assertNotEmpty($response->json('data.token'));
    }

    public function test_user_cannot_login_with_invalid_credentials()
    {
        $user = User::factory()->create([
            'email' => 'donor@test.com',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'donor@test.com',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_authenticated_user_can_fetch_their_profile()
    {
        $user = User::factory()->create([
            'role' => 'donor',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->getJson('/api/auth/me', [
            'Authorization' => 'Bearer '.$token,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.email', $user->email)
            ->assertJsonPath('data.role', 'donor');
    }

    public function test_unauthenticated_user_cannot_fetch_profile()
    {
        $response = $this->getJson('/api/auth/me');

        $response->assertStatus(401);
    }

    public function test_user_can_logout()
    {
        $user = User::factory()->create([
            'role' => 'donor',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->postJson('/api/auth/logout', [], [
            'Authorization' => 'Bearer '.$token,
        ]);

        $response->assertOk()
            ->assertJsonPath('message', 'Đăng xuất thành công.');

        $this->assertCount(0, $user->tokens);
    }

    public function test_new_donor_can_register()
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'Người Hiến Mới',
            'email' => 'newdonor@test.com',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
            'phone' => '0900123456',
            'blood_type' => 'O+',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure(['data' => ['token', 'user' => ['id', 'name', 'email', 'role']]])
            ->assertJsonPath('data.user.role', 'donor');

        $this->assertDatabaseHas('users', [
            'email' => 'newdonor@test.com',
            'role' => 'donor',
            'id_verification_status' => 'unverified',
        ]);
    }

    public function test_register_rejects_duplicate_email_and_mismatched_password()
    {
        User::factory()->create(['email' => 'taken@test.com']);

        $this->postJson('/api/auth/register', [
            'name' => 'Trùng Email',
            'email' => 'taken@test.com',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
        ])->assertStatus(422)->assertJsonValidationErrors(['email']);

        $this->postJson('/api/auth/register', [
            'name' => 'Sai Xác Nhận',
            'email' => 'fresh@test.com',
            'password' => 'secret123',
            'password_confirmation' => 'different',
        ])->assertStatus(422)->assertJsonValidationErrors(['password']);
    }

    public function test_donor_submitting_id_card_moves_to_pending_verification()
    {
        $user = User::factory()->create(['role' => 'donor']);
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->postJson('/api/mobile/me/hero-pass', [
            'national_id' => '012345678901',
            'id_card_front_url' => 'https://cdn.test/front.jpg',
            'id_card_back_url' => 'https://cdn.test/back.jpg',
        ], [
            'Authorization' => 'Bearer '.$token,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.id_verification_status', 'pending');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'national_id' => '012345678901',
            'id_verification_status' => 'pending',
        ]);
    }

    public function test_donor_submitting_id_card_images_without_national_id_is_rejected()
    {
        $user = User::factory()->create(['role' => 'donor']);
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->postJson('/api/mobile/me/hero-pass', [
            'id_card_front_url' => 'https://cdn.test/front.jpg',
            'id_card_back_url' => 'https://cdn.test/back.jpg',
        ], [
            'Authorization' => 'Bearer '.$token,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['national_id']);

        $user->refresh();
        $this->assertNull($user->national_id);
        $this->assertNull($user->id_card_front_url);
        $this->assertNull($user->id_card_back_url);
        $this->assertSame('unverified', $user->id_verification_status);
    }

    public function test_admin_can_approve_id_verification()
    {
        $donor = User::factory()->create([
            'role' => 'donor',
            'national_id' => '012345678901',
            'id_card_front_url' => 'https://cdn.test/front.jpg',
            'id_card_back_url' => 'https://cdn.test/back.jpg',
            'id_verification_status' => 'pending',
        ]);

        $admin = User::factory()->create(['role' => 'system_admin']);
        $token = $admin->createToken('admin-token')->plainTextToken;

        $this->getJson('/api/admin/id-verifications?status=pending', [
            'Authorization' => 'Bearer '.$token,
        ])->assertOk()->assertJsonPath('data.0.id', $donor->id);

        $this->postJson("/api/admin/id-verifications/{$donor->id}/approve", [], [
            'Authorization' => 'Bearer '.$token,
        ])->assertOk()->assertJsonPath('data.id_verification_status', 'verified');

        $this->assertDatabaseHas('users', [
            'id' => $donor->id,
            'id_verification_status' => 'verified',
        ]);
    }
}
