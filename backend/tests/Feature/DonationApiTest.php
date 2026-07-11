<?php

namespace Tests\Feature;

use App\Events\CampaignProgressUpdated;
use App\Models\CampaignDonation;
use App\Models\DonationCampaign;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

class DonationApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $donor;

    protected User $admin;

    protected string $donorToken;

    protected string $adminToken;

    protected function setUp(): void
    {
        parent::setUp();

        config(['services.donations.cash_enabled' => true]);

        // Create a donor
        $this->donor = User::factory()->create([
            'role' => 'donor',
            'points' => 1000,
        ]);
        $this->donorToken = $this->donor->createToken('donor-token')->plainTextToken;

        // Create a system admin
        $this->admin = User::factory()->create([
            'role' => 'system_admin',
        ]);
        $this->adminToken = $this->admin->createToken('admin-token')->plainTextToken;
    }

    public function test_donor_can_retrieve_campaign_list()
    {
        DonationCampaign::create([
            'title' => 'Campaign 1',
            'description' => 'Description 1',
            'target_amount' => 50000000,
            'status' => 'active',
        ]);

        DonationCampaign::create([
            'title' => 'Campaign 2',
            'description' => 'Description 2',
            'target_amount' => 10000000,
            'status' => 'completed', // completed shouldn't show in active list
        ]);

        $response = $this->getJson('/api/mobile/donation/campaigns', [
            'Authorization' => 'Bearer '.$this->donorToken,
        ]);

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'Campaign 1');
    }

    public function test_donor_can_retrieve_campaign_details_with_leaderboard()
    {
        $campaign = DonationCampaign::create([
            'title' => 'SOS Case Fund',
            'description' => 'Help poor patient',
            'target_amount' => 10000000,
            'target_points' => 1000,
            'status' => 'active',
        ]);

        // Create some success donations
        CampaignDonation::create([
            'donation_campaign_id' => $campaign->id,
            'user_id' => $this->donor->id,
            'amount' => 500000,
            'points' => 50,
            'payment_method' => 'momo',
            'payment_status' => 'success',
            'donor_name' => 'Donor A',
        ]);

        $response = $this->getJson('/api/mobile/donation/campaigns/'.$campaign->public_id, [
            'Authorization' => 'Bearer '.$this->donorToken,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.campaign.title', 'SOS Case Fund')
            ->assertJsonCount(1, 'data.leaderboard')
            ->assertJsonPath('data.leaderboard.0.donor_name', 'Donor A');
    }

    public function test_donor_can_donate_points_success()
    {
        Event::fake([CampaignProgressUpdated::class]);

        $campaign = DonationCampaign::create([
            'title' => 'Village Food Pack',
            'description' => 'Sponsor food packs',
            'status' => 'active',
        ]);

        $response = $this->postJson('/api/mobile/donation/campaigns/'.$campaign->public_id.'/donate-points', [
            'points' => 200,
            'donor_name' => 'Hero Helper',
            'message' => 'Keep it up!',
            'is_anonymous' => false,
        ], [
            'Authorization' => 'Bearer '.$this->donorToken,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.remaining_points', 800);

        // Verify database
        $this->assertDatabaseHas('campaign_donations', [
            'donation_campaign_id' => $campaign->id,
            'points' => 200,
            'payment_status' => 'success',
            'donor_name' => 'Hero Helper',
        ]);

        $campaign->refresh();
        // Điểm được quy đổi ra tiền (200 điểm × 250đ) và gộp vào current_amount.
        $this->assertEquals(200 * DonationCampaign::POINT_VALUE_VND, $campaign->current_amount);

        Event::assertDispatched(CampaignProgressUpdated::class);
    }

    public function test_donor_cannot_donate_points_insufficient_balance()
    {
        $campaign = DonationCampaign::create([
            'title' => 'Village Food Pack',
            'description' => 'Sponsor food packs',
            'status' => 'active',
        ]);

        $response = $this->postJson('/api/mobile/donation/campaigns/'.$campaign->public_id.'/donate-points', [
            'points' => 5000, // donor only has 1000 Pts
        ], [
            'Authorization' => 'Bearer '.$this->donorToken,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('points');
    }

    public function test_donor_can_register_cash_donation_pending()
    {
        $campaign = DonationCampaign::create([
            'title' => 'SOS Surgery Fund',
            'description' => 'Help heart surgery',
            'target_amount' => 100000000,
            'status' => 'active',
        ]);

        $response = $this->postJson('/api/mobile/donation/campaigns/'.$campaign->public_id.'/donate-cash', [
            'amount' => 500000,
            'payment_method' => 'vnpay',
            'donor_name' => 'Anonymous Donor',
            'message' => 'Get well soon',
            'is_anonymous' => true,
        ], [
            'Authorization' => 'Bearer '.$this->donorToken,
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure(['data' => ['donation_id', 'transaction_id', 'payment_url']]);

        // Verify database has pending txn
        $this->assertDatabaseHas('campaign_donations', [
            'donation_campaign_id' => $campaign->id,
            'amount' => 500000,
            'payment_status' => 'pending',
            'is_anonymous' => true,
        ]);
    }

    public function test_cash_donation_can_be_disabled_without_affecting_points(): void
    {
        config(['services.donations.cash_enabled' => false]);
        $campaign = DonationCampaign::create([
            'title' => 'Disabled Cash Fund',
            'description' => 'Cash gateway is disabled',
            'status' => 'active',
        ]);

        $this->postJson('/api/mobile/donation/campaigns/'.$campaign->public_id.'/donate-cash', [
            'amount' => 500000,
            'payment_method' => 'vnpay',
        ], [
            'Authorization' => 'Bearer '.$this->donorToken,
        ])
            ->assertForbidden()
            ->assertJsonPath(
                'message',
                'Tính năng quyên góp tiền đang tạm tắt trên hệ thống. Bạn vẫn có thể đồng hành bằng điểm Hero.',
            );
    }

    public function test_donor_can_donate_cash_without_optional_fields()
    {
        $campaign = DonationCampaign::create([
            'title' => 'SOS Surgery Fund',
            'description' => 'Help heart surgery',
            'target_amount' => 100000000,
            'status' => 'active',
        ]);

        $response = $this->postJson('/api/mobile/donation/campaigns/'.$campaign->public_id.'/donate-cash', [
            'amount' => 500000,
            'payment_method' => 'vnpay',
        ], [
            'Authorization' => 'Bearer '.$this->donorToken,
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('campaign_donations', [
            'donation_campaign_id' => $campaign->id,
            'amount' => 500000,
            'payment_status' => 'pending',
            'donor_name' => $this->donor->name, // defaults to user name
            'message' => null,
            'is_anonymous' => false,
        ]);
    }

    public function test_webhook_can_mark_pending_cash_donation_successful()
    {
        Event::fake([CampaignProgressUpdated::class]);

        $campaign = DonationCampaign::create([
            'title' => 'SOS Surgery Fund',
            'description' => 'Help heart surgery',
            'target_amount' => 100000000,
            'status' => 'active',
        ]);

        $donation = CampaignDonation::create([
            'donation_campaign_id' => $campaign->id,
            'user_id' => $this->donor->id,
            'amount' => 500000,
            'payment_method' => 'momo',
            'payment_status' => 'pending',
            'transaction_id' => 'TXN-ABC123XYZ',
            'donor_name' => 'Donor A',
        ]);

        // Call Webhook
        $response = $this->postJson('/api/payment/webhook', [
            'transaction_id' => 'TXN-ABC123XYZ',
            'status' => 'success',
        ]);

        $response->assertStatus(200);

        $donation->refresh();
        $this->assertEquals('success', $donation->payment_status);

        $campaign->refresh();
        $this->assertEquals(500000, $campaign->current_amount);

        Event::assertDispatched(CampaignProgressUpdated::class);
    }

    public function test_donor_can_check_transaction_status()
    {
        $campaign = DonationCampaign::create([
            'title' => 'SOS Surgery Fund',
            'description' => 'Help heart surgery',
            'target_amount' => 100000000,
            'status' => 'active',
        ]);

        $donation = CampaignDonation::create([
            'donation_campaign_id' => $campaign->id,
            'user_id' => $this->donor->id,
            'amount' => 500000,
            'payment_method' => 'momo',
            'payment_status' => 'pending',
            'transaction_id' => 'TXN-CHECKSTATUS',
            'donor_name' => 'Donor A',
        ]);

        $response = $this->getJson('/api/mobile/donation/transactions/TXN-CHECKSTATUS/status', [
            'Authorization' => 'Bearer '.$this->donorToken,
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'pending');
    }

    public function test_admin_can_manage_campaigns()
    {
        // 1. Store campaign
        $response = $this->postJson('/api/admin/campaigns', [
            'title' => 'Admin Campaign',
            'description' => 'Admin description',
            'target_amount' => 20000000,
            'target_points' => 2000,
        ], [
            'Authorization' => 'Bearer '.$this->adminToken,
        ]);

        $response->assertStatus(211); // Custom create status or 201

        $this->assertDatabaseHas('donation_campaigns', [
            'title' => 'Admin Campaign',
            'target_amount' => 20000000,
        ]);

        $campaignId = DonationCampaign::query()->first()->id;

        // 2. View transactions
        $txResponse = $this->getJson('/api/admin/campaigns/'.$campaignId.'/transactions', [
            'Authorization' => 'Bearer '.$this->adminToken,
        ]);
        $txResponse->assertStatus(200);

        // 3. Update campaign
        $updateResponse = $this->putJson('/api/admin/campaigns/'.$campaignId, [
            'title' => 'Updated Admin Campaign',
            'status' => 'completed',
        ], [
            'Authorization' => 'Bearer '.$this->adminToken,
        ]);
        $updateResponse->assertStatus(200);
        $this->assertDatabaseHas('donation_campaigns', [
            'id' => $campaignId,
            'title' => 'Updated Admin Campaign',
            'status' => 'completed',
        ]);

        // 4. Delete campaign
        $deleteResponse = $this->deleteJson('/api/admin/campaigns/'.$campaignId, [], [
            'Authorization' => 'Bearer '.$this->adminToken,
        ]);
        $deleteResponse->assertStatus(200);
        $this->assertDatabaseMissing('donation_campaigns', [
            'id' => $campaignId,
        ]);
    }
}
