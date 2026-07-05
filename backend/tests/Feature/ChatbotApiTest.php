<?php

namespace Tests\Feature;

use App\Models\AppSetting;
use App\Models\ChatConversation;
use App\Models\ChatMessage;
use App\Models\DonationHistory;
use App\Models\User;
use App\Models\Hospital;
use App\Services\Contracts\AiChatResponse;
use App\Services\Contracts\AiChatService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class ChatbotApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $donor;
    protected User $admin;
    protected string $donorToken;
    protected string $adminToken;

    protected function setUp(): void
    {
        parent::setUp();

        // Create a donor
        $this->donor = User::factory()->create([
            'role' => 'donor',
            'blood_type' => 'O+',
        ]);
        $this->donorToken = $this->donor->createToken('donor-token')->plainTextToken;

        // Create a system admin
        $this->admin = User::factory()->create([
            'role' => 'system_admin',
        ]);
        $this->adminToken = $this->admin->createToken('admin-token')->plainTextToken;
    }

    public function test_mobile_user_can_retrieve_conversations()
    {
        ChatConversation::create([
            'user_id' => $this->donor->id,
            'title' => 'Trò chuyện 1',
            'context_type' => 'general',
            'is_active' => true,
        ]);

        $response = $this->getJson('/api/mobile/me/chats?user_id=' . $this->donor->id, [
            'Authorization' => 'Bearer ' . $this->donorToken,
        ]);

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Trò chuyện 1');
    }

    public function test_mobile_user_can_create_conversation()
    {
        $response = $this->postJson('/api/mobile/me/chats?user_id=' . $this->donor->id, [
            'context_type' => 'general',
            'title' => 'Hội thoại mới tạo'
        ], [
            'Authorization' => 'Bearer ' . $this->donorToken,
        ]);

        $response->assertStatus(210)
            ->assertJsonPath('data.title', 'Hội thoại mới tạo')
            ->assertJsonPath('data.context_type', 'general');

        $this->assertDatabaseHas('chat_conversations', [
            'user_id' => $this->donor->id,
            'title' => 'Hội thoại mới tạo',
        ]);
    }

    public function test_mobile_user_can_send_message_and_receive_ai_reply()
    {
        // Mock the AI service
        $this->mock(AiChatService::class, function ($mock) {
            $mock->shouldReceive('generateReply')->once()->andReturn(
                new AiChatResponse('Phản hồi giả định của AI', 'gemini', 50)
            );
        });

        $chat = ChatConversation::create([
            'user_id' => $this->donor->id,
            'title' => 'Cuộc trò chuyện mới',
            'context_type' => 'general',
            'is_active' => true,
        ]);

        $response = $this->postJson("/api/mobile/me/chats/{$chat->id}/messages?user_id=" . $this->donor->id, [
            'content' => 'Tôi nên ăn gì sau hiến máu?'
        ], [
            'Authorization' => 'Bearer ' . $this->donorToken,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.content', 'Phản hồi giả định của AI')
            ->assertJsonPath('data.role', 'assistant');

        $this->assertDatabaseHas('chat_messages', [
            'chat_conversation_id' => $chat->id,
            'role' => 'user',
            'content' => 'Tôi nên ăn gì sau hiến máu?',
        ]);

        $this->assertDatabaseHas('chat_messages', [
            'chat_conversation_id' => $chat->id,
            'role' => 'assistant',
            'content' => 'Phản hồi giả định của AI',
        ]);
    }

    public function test_daily_message_limit_quota()
    {
        // Enable quota limit
        AppSetting::set('chat_daily_limit', 1);

        $chat = ChatConversation::create([
            'user_id' => $this->donor->id,
            'title' => 'Test Quota Chat',
            'context_type' => 'general',
            'is_active' => true,
        ]);

        // First message
        ChatMessage::create([
            'chat_conversation_id' => $chat->id,
            'role' => 'user',
            'content' => 'Tin nhắn số 1',
        ]);

        // Attempting to send second message
        $response = $this->postJson("/api/mobile/me/chats/{$chat->id}/messages?user_id=" . $this->donor->id, [
            'content' => 'Tin nhắn số 2 vượt quota'
        ], [
            'Authorization' => 'Bearer ' . $this->donorToken,
        ]);

        $response->assertStatus(429)
            ->assertJsonPath('remaining', 0);
    }

    public function test_admin_can_retrieve_and_update_ai_settings()
    {
        // Get settings
        $response = $this->getJson('/api/admin/settings', [
            'Authorization' => 'Bearer ' . $this->adminToken,
        ]);

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'ai_primary_provider',
                    'gemini_api_key',
                    'gemini_model_name',
                    'groq_api_key',
                    'groq_model_name',
                    'chat_daily_limit',
                ]
            ]);

        // Update settings
        $updateResponse = $this->putJson('/api/admin/settings', [
            'ai_primary_provider' => 'groq',
            'gemini_api_key' => 'new-gemini-key',
            'gemini_model_name' => 'gemini-1.5-pro',
            'groq_api_key' => 'new-groq-key',
            'groq_model_name' => 'mixtral-8x7b-32768',
            'chat_daily_limit' => 15,
        ], [
            'Authorization' => 'Bearer ' . $this->adminToken,
        ]);

        $updateResponse->assertOk();

        $this->assertEquals('groq', AppSetting::get('ai_primary_provider'));
        $this->assertEquals('gemini-1.5-pro', AppSetting::get('gemini_model_name'));
        $this->assertEquals('mixtral-8x7b-32768', AppSetting::get('groq_model_name'));
        $this->assertEquals(15, AppSetting::get('chat_daily_limit'));
    }

    public function test_post_donation_checkup_scheduler()
    {
        $hospital = Hospital::firstOrCreate([
            'code' => 'TEST-HOSP',
        ], [
            'name' => 'Bệnh viện Kiểm thử',
            'province_code' => '01',
            'address' => '123 Test Street',
            'latitude' => 21.0285,
            'longitude' => 105.8542,
            'is_active' => true,
        ]);

        // Create a donation verified 25 hours ago
        $donation = DonationHistory::create([
            'user_id' => $this->donor->id,
            'hospital_id' => $hospital->id,
            'donation_type' => 'regular',
            'donated_at' => Carbon::yesterday()->toDateString(),
            'location_name' => $hospital->name,
            'volume_ml' => 350,
            'blood_type' => 'O+',
            'certificate_id' => 'PL-TEST-CERT',
            'status' => 'verified',
        ]);

        // Run the artisan command
        $this->artisan('app:send-post-donation-checkup')
            ->assertSuccessful();

        // Check if chat conversation was automatically created
        $this->assertDatabaseHas('chat_conversations', [
            'user_id' => $this->donor->id,
            'context_type' => 'post_donation_checkup',
        ]);

        // Check if message asks about health
        $this->assertDatabaseHas('chat_messages', [
            'role' => 'assistant',
        ]);

        // Check if mobile notification was created
        $this->assertDatabaseHas('mobile_notifications', [
            'user_id' => $this->donor->id,
            'type' => 'post_donation_checkup',
        ]);
    }

    public function test_appointment_creates_pre_donation_guidance_chat()
    {
        $hospital = Hospital::firstOrCreate([
            'code' => 'TEST-HOSP',
        ], [
            'name' => 'Bệnh viện Kiểm thử',
            'province_code' => '01',
            'address' => '123 Test Street',
            'latitude' => 21.0285,
            'longitude' => 105.8542,
            'is_active' => true,
        ]);

        $event = \App\Models\DonationEvent::create([
            'hospital_id' => $hospital->id,
            'title' => 'Sự kiện Hiến Máu Test',
            'starts_at' => now()->addDays(2),
            'ends_at' => now()->addDays(2)->addHours(4),
            'location_name' => 'Bệnh viện Kiểm thử',
            'organizer' => 'Bệnh viện Kiểm thử',
            'latitude' => 21.0285,
            'longitude' => 105.8542,
            'capacity' => 100,
            'is_published' => true,
        ]);

        // Creating appointment should trigger Pre-donation chat
        $appointment = \App\Models\DonationAppointment::create([
            'donation_event_id' => $event->id,
            'user_id' => $this->donor->id,
            'status' => 'booked',
            'booked_at' => now(),
        ]);

        $this->assertDatabaseHas('chat_conversations', [
            'user_id' => $this->donor->id,
            'context_type' => 'pre_donation_guidance',
        ]);

        $this->assertDatabaseHas('mobile_notifications', [
            'user_id' => $this->donor->id,
            'type' => 'pre_donation_guidance',
        ]);
    }

    public function test_appointment_deferred_creates_counseling_chat()
    {
        $hospital = Hospital::firstOrCreate([
            'code' => 'TEST-HOSP',
        ], [
            'name' => 'Bệnh viện Kiểm thử',
            'province_code' => '01',
            'address' => '123 Test Street',
            'latitude' => 21.0285,
            'longitude' => 105.8542,
            'is_active' => true,
        ]);

        $event = \App\Models\DonationEvent::create([
            'hospital_id' => $hospital->id,
            'title' => 'Sự kiện Hiến Máu Test 2',
            'starts_at' => now()->addDays(2),
            'ends_at' => now()->addDays(2)->addHours(4),
            'location_name' => 'Bệnh viện Kiểm thử',
            'organizer' => 'Bệnh viện Kiểm thử',
            'latitude' => 21.0285,
            'longitude' => 105.8542,
            'capacity' => 100,
            'is_published' => true,
        ]);

        $appointment = \App\Models\DonationAppointment::create([
            'donation_event_id' => $event->id,
            'user_id' => $this->donor->id,
            'status' => 'booked',
            'booked_at' => now(),
        ]);

        // Updating status to deferred should trigger Deferred counseling chat
        $appointment->update([
            'status' => 'deferred',
            'screening_notes' => 'Huyết áp thấp',
        ]);

        $this->assertDatabaseHas('chat_conversations', [
            'user_id' => $this->donor->id,
            'context_type' => 'donation_deferred',
        ]);

        $this->assertDatabaseHas('mobile_notifications', [
            'user_id' => $this->donor->id,
            'type' => 'donation_deferred',
        ]);
    }

    public function test_send_appointment_reminder_command()
    {
        $hospital = Hospital::firstOrCreate([
            'code' => 'TEST-HOSP',
        ], [
            'name' => 'Bệnh viện Kiểm thử',
            'province_code' => '01',
            'address' => '123 Test Street',
            'latitude' => 21.0285,
            'longitude' => 105.8542,
            'is_active' => true,
        ]);

        // Create an event that starts today
        $event = \App\Models\DonationEvent::create([
            'hospital_id' => $hospital->id,
            'title' => 'Sự kiện Hôm Nay',
            'starts_at' => now()->addHours(2),
            'ends_at' => now()->addHours(6),
            'location_name' => 'Bệnh viện Kiểm thử',
            'organizer' => 'Bệnh viện Kiểm thử',
            'latitude' => 21.0285,
            'longitude' => 105.8542,
            'capacity' => 100,
            'is_published' => true,
        ]);

        $appointment = \App\Models\DonationAppointment::create([
            'donation_event_id' => $event->id,
            'user_id' => $this->donor->id,
            'status' => 'booked',
            'booked_at' => now(),
        ]);

        // Run Artisan command
        $this->artisan('app:send-appointment-reminder')
            ->assertSuccessful();

        $this->assertDatabaseHas('chat_conversations', [
            'user_id' => $this->donor->id,
            'context_type' => 'appointment_reminder',
        ]);

        $this->assertDatabaseHas('mobile_notifications', [
            'user_id' => $this->donor->id,
            'type' => 'appointment_reminder',
        ]);
    }
}
