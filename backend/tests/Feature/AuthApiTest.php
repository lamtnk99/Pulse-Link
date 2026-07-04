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
}
