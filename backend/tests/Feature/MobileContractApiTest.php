<?php

namespace Tests\Feature;

use App\Events\EmergencyAlertActivated;
use App\Events\EmergencyCommitmentUpdated;
use App\Models\CommunityPost;
use App\Models\DonationEvent;
use App\Models\DonationHistory;
use App\Models\EmergencyAlert;
use App\Models\Hospital;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class MobileContractApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_mobile_daily_contract_includes_location_master_fields(): void
    {
        $this->seed();

        $donor = User::query()->where('role', 'donor')->firstOrFail();

        $this->getJson("/api/mobile/me/hero-pass?user_id={$donor->id}")
            ->assertOk()
            ->assertJsonPath('data.province_code', $donor->province_code)
            ->assertJsonPath('data.province.code', $donor->province_code);

        $this->getJson("/api/mobile/donation-events?user_id={$donor->id}")
            ->assertOk()
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'province_code',
                        'province' => ['code', 'full_name'],
                        'ward_code',
                        'location' => ['latitude', 'longitude'],
                        'distance_km',
                    ],
                ],
            ])
            ->assertJsonPath('data.0.booked', true);
    }

    public function test_mobile_can_manage_push_devices_and_notification_preferences(): void
    {
        $this->seed();
        $donor = User::query()->where('role', 'donor')->firstOrFail();

        $this->getJson("/api/mobile/me/notification-preferences?user_id={$donor->id}")
            ->assertOk()
            ->assertJsonPath('data.sos_enabled', true)
            ->assertJsonPath('data.nearby_events_enabled', false);

        $this->putJson("/api/mobile/me/notification-preferences?user_id={$donor->id}", [
            'care_enabled' => false,
            'nearby_events_enabled' => true,
            'quiet_hours_start' => '22:00',
            'quiet_hours_end' => '07:00',
        ])
            ->assertOk()
            ->assertJsonPath('data.care_enabled', false)
            ->assertJsonPath('data.nearby_events_enabled', true)
            ->assertJsonPath('data.quiet_hours_start', '22:00');

        $this->postJson("/api/mobile/me/notification-devices?user_id={$donor->id}", [
            'token' => 'firebase-device-token',
            'platform' => 'ios',
            'app_version' => '0.1.0',
        ])
            ->assertOk()
            ->assertJsonPath('data.platform', 'ios')
            ->assertJsonPath('data.enabled', true);

        $this->assertDatabaseHas('notification_devices', [
            'user_id' => $donor->id,
            'token' => 'firebase-device-token',
            'platform' => 'ios',
        ]);

        $this->deleteJson("/api/mobile/me/notification-devices?user_id={$donor->id}", [
            'token' => 'firebase-device-token',
        ])
            ->assertOk()
            ->assertJsonPath('data.removed', true);

        $testPushResponse = $this->postJson("/api/mobile/me/notifications/test?user_id={$donor->id}")
            ->assertOk();
        $this->assertContains(
            $testPushResponse->json('data.status'),
            ['no_device', 'skipped'],
        );

        $this->assertDatabaseHas('mobile_notifications', [
            'user_id' => $donor->id,
            'type' => 'system_test',
        ]);
    }

    public function test_mobile_donation_history_orders_same_day_records_by_issued_time(): void
    {
        $this->seed();

        $donor = User::factory()->create([
            'role' => 'donor',
            'blood_type' => 'O+',
        ]);
        $hospital = Hospital::query()->firstOrFail();
        $donatedAt = now()->startOfDay();

        $earlier = DonationHistory::query()->create([
            'user_id' => $donor->id,
            'hospital_id' => $hospital->id,
            'donation_type' => 'sos',
            'donated_at' => $donatedAt,
            'location_name' => $hospital->name,
            'volume_ml' => 250,
            'blood_type' => 'O+',
            'certificate_id' => 'SOS-EARLIER-'.$donor->id,
            'certificate_issued_at' => now()->subMinutes(5),
            'status' => 'verified',
        ]);
        $later = DonationHistory::query()->create([
            'user_id' => $donor->id,
            'hospital_id' => $hospital->id,
            'donation_type' => 'sos',
            'donated_at' => $donatedAt,
            'location_name' => $hospital->name,
            'volume_ml' => 350,
            'blood_type' => 'O+',
            'certificate_id' => 'SOS-LATER-'.$donor->id,
            'certificate_issued_at' => now(),
            'status' => 'verified',
        ]);

        $this->getJson("/api/mobile/me/donations?user_id={$donor->id}")
            ->assertOk()
            ->assertJsonPath('data.0.id', (string) $later->id)
            ->assertJsonPath('data.1.id', (string) $earlier->id);
    }

    public function test_mobile_daily_mode_exposes_event_detail_appointments_and_posts(): void
    {
        $this->seed();

        $donor = User::query()->where('role', 'donor')->firstOrFail();
        $event = DonationEvent::query()->whereHas('appointments', function ($query) use ($donor): void {
            $query->where('user_id', $donor->id)->where('status', 'booked');
        })->firstOrFail();
        $post = CommunityPost::query()->where('status', 'published')->latest('published_at')->firstOrFail();

        $this->getJson("/api/mobile/donation-events/{$event->id}?user_id={$donor->id}")
            ->assertOk()
            ->assertJsonPath('data.id', (string) $event->id)
            ->assertJsonPath('data.booked', true)
            ->assertJsonPath('data.appointment_status', 'booked')
            ->assertJsonStructure([
                'data' => [
                    'description',
                    'hospital' => ['id', 'name'],
                    'province' => ['code', 'full_name'],
                ],
            ]);

        $this->getJson("/api/mobile/me/appointments?user_id={$donor->id}")
            ->assertOk()
            ->assertJsonPath('data.0.status', 'booked')
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'booked_at',
                        'event' => ['id', 'title', 'booked'],
                    ],
                ],
            ]);

        $this->getJson("/api/mobile/community-posts?user_id={$donor->id}")
            ->assertOk()
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'slug',
                        'title',
                        'excerpt',
                        'content',
                        'published_at',
                        'audience_label',
                    ],
                ],
            ]);

        $this->getJson("/api/mobile/community-posts/{$post->slug}?user_id={$donor->id}")
            ->assertOk()
            ->assertJsonPath('data.slug', $post->slug)
            ->assertJsonPath('data.status', 'published');
    }

    public function test_admin_can_create_daily_event_and_community_post(): void
    {
        $this->seed();

        $this->postJson('/api/admin/donation-events', [
            'title' => 'Ngày hội hiến máu tại Quận 7',
            'organizer' => 'Bệnh viện Chợ Rẫy',
            'description' => 'Sự kiện kiểm thử contract admin.',
            'starts_at' => now()->addDays(7)->setTime(8, 0)->toIso8601String(),
            'ends_at' => now()->addDays(7)->setTime(12, 0)->toIso8601String(),
            'location_name' => 'Nhà văn hóa Quận 7, TP.HCM',
            'province_code' => '79',
            'ward_code' => '27301',
            'latitude' => 10.7362,
            'longitude' => 106.7218,
            'urgency' => 'normal',
            'capacity' => 120,
            'is_published' => true,
        ])
            ->assertCreated()
            ->assertJsonPath('data.province_code', '79')
            ->assertJsonPath('data.ward_code', '27301');

        $this->postJson('/api/admin/community-posts', [
            'title' => 'Thông báo lịch hiến máu kiểm thử',
            'excerpt' => 'Bản tin kiểm thử API admin.',
            'content' => 'Nội dung kiểm thử bài viết cộng đồng.',
            'status' => 'published',
            'audience_type' => 'province',
            'province_code' => '79',
            'ward_code' => '27301',
        ])
            ->assertCreated()
            ->assertJsonPath('data.status', 'published')
            ->assertJsonPath('data.province_code', '79');
    }

    public function test_mobile_route_plan_contract_matches_flutter_parser(): void
    {
        $this->seed();

        $this->postJson('/api/mobile/routes/plan', [
            'origin' => ['latitude' => 10.7727, 'longitude' => 106.6663],
            'destination' => ['latitude' => 10.7565, 'longitude' => 106.6594],
        ])
            ->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'polyline' => [
                        '*' => ['latitude', 'longitude'],
                    ],
                    'distance_km',
                    'estimated_minutes',
                    'summary',
                ],
            ]);
    }

    public function test_mobile_sos_commit_accepts_explicit_donor_identity(): void
    {
        Event::fake();
        $this->seed();

        $alert = EmergencyAlert::query()->where('status', 'active')->firstOrFail();
        $donor = User::query()->where('role', 'donor')->whereNotNull('latitude')->firstOrFail();

        $this->postJson("/api/mobile/sos-alerts/{$alert->public_id}/commit", [
            'donor_id' => $donor->id,
            'latitude' => $donor->latitude,
            'longitude' => $donor->longitude,
            'eta_minutes' => 12,
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'committed')
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'alert_id',
                    'status',
                    'latitude',
                    'longitude',
                    'eta_minutes',
                    'committed_at',
                    'donor' => ['id', 'name', 'blood_type'],
                ],
            ]);

        $this->assertDatabaseHas('emergency_commitments', [
            'emergency_alert_id' => $alert->id,
            'donor_id' => $donor->id,
            'eta_minutes' => 12,
        ]);
    }

    public function test_mobile_can_resume_active_sos_commitment(): void
    {
        Event::fake();
        $this->seed();

        $alert = EmergencyAlert::query()->where('status', 'active')->firstOrFail();
        $donor = User::query()->where('role', 'donor')->whereNotNull('latitude')->firstOrFail();

        $this->postJson("/api/mobile/sos-alerts/{$alert->public_id}/commit", [
            'donor_id' => $donor->id,
            'latitude' => $donor->latitude,
            'longitude' => $donor->longitude,
            'eta_minutes' => 12,
        ])->assertOk();

        $this->getJson("/api/mobile/me/sos-commitment?user_id={$donor->id}")
            ->assertOk()
            ->assertJsonPath('data.alert.id', $alert->public_id)
            ->assertJsonPath('data.commitment.alert_id', $alert->public_id)
            ->assertJsonPath('data.commitment.status', 'committed')
            ->assertJsonStructure([
                'data' => [
                    'alert' => [
                        'id',
                        'hospital_name',
                        'hospital_location' => ['latitude', 'longitude'],
                    ],
                    'commitment' => [
                        'id',
                        'alert_id',
                        'status',
                        'latitude',
                        'longitude',
                        'eta_minutes',
                    ],
                ],
            ]);

        $alerts = $this->getJson("/api/mobile/sos-alerts?user_id={$donor->id}")
            ->assertOk()
            ->assertJsonFragment([
                'id' => $alert->public_id,
                'status' => 'committed',
            ])
            ->json('data');
        $committedAlert = collect($alerts)->firstWhere('id', $alert->public_id);
        $this->assertSame($alert->public_id, $committedAlert['current_commitment']['alert_id']);
        $this->assertSame('committed', $committedAlert['current_commitment']['status']);
    }

    public function test_mobile_realtime_config_and_channels_are_exposed(): void
    {
        Event::fake();
        config([
            'broadcasting.default' => 'reverb',
            'broadcasting.connections.reverb.key' => 'pulse-link-key',
            'broadcasting.connections.reverb.options.host' => 'api.pulselink.asia',
            'broadcasting.connections.reverb.options.port' => 443,
            'broadcasting.connections.reverb.options.scheme' => 'https',
        ]);
        $this->seed();

        $alert = EmergencyAlert::query()->where('status', 'active')->firstOrFail();
        $donor = User::query()->where('role', 'donor')->whereNotNull('latitude')->firstOrFail();

        $this->postJson("/api/mobile/sos-alerts/{$alert->public_id}/commit", [
            'donor_id' => $donor->id,
            'eta_minutes' => 12,
        ])->assertOk();
        $commitment = $alert->commitments()->where('donor_id', $donor->id)->firstOrFail();

        $this->getJson('/api/mobile/realtime-config')
            ->assertOk()
            ->assertJsonPath('data.enabled', true)
            ->assertJsonPath('data.host', 'api.pulselink.asia')
            ->assertJsonPath('data.port', 443)
            ->assertJsonPath('data.scheme', 'https')
            ->assertJsonPath('data.channels.global', 'mobile.emergency-alerts')
            ->assertJsonPath('data.channels.donor', 'mobile.donor.{donor_id}');

        $alertChannels = collect((new EmergencyAlertActivated($alert))->broadcastOn())
            ->map(fn ($channel) => $channel->name)
            ->all();
        $commitmentChannels = collect((new EmergencyCommitmentUpdated($commitment))->broadcastOn())
            ->map(fn ($channel) => $channel->name)
            ->all();

        $this->assertContains('mobile.emergency-alerts', $alertChannels);
        $this->assertContains('mobile.donor.'.$donor->id, $commitmentChannels);
    }

    public function test_mobile_sos_commit_still_works_before_cancel_reason_migration(): void
    {
        Event::fake();
        $this->seed();
        Schema::table('emergency_commitments', function ($table): void {
            $table->dropColumn('cancel_reason');
        });

        $alert = EmergencyAlert::query()->where('status', 'active')->firstOrFail();
        $donor = User::query()->where('role', 'donor')->whereNotNull('latitude')->firstOrFail();

        $this->postJson("/api/mobile/sos-alerts/{$alert->public_id}/commit", [
            'donor_id' => $donor->id,
            'latitude' => $donor->latitude,
            'longitude' => $donor->longitude,
            'eta_minutes' => 12,
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'committed')
            ->assertJsonPath('data.alert_id', $alert->public_id);

        $this->assertDatabaseHas('emergency_commitments', [
            'emergency_alert_id' => $alert->id,
            'donor_id' => $donor->id,
            'status' => 'committed',
        ]);
    }

    public function test_mobile_can_cancel_sos_commitment_with_reason(): void
    {
        Event::fake();
        $this->seed();

        $alert = EmergencyAlert::query()->where('status', 'active')->firstOrFail();
        $donor = User::query()->where('role', 'donor')->whereNotNull('latitude')->firstOrFail();

        $this->postJson("/api/mobile/sos-alerts/{$alert->public_id}/commit", [
            'donor_id' => $donor->id,
            'eta_minutes' => 12,
        ])->assertOk();

        $this->postJson("/api/mobile/sos-alerts/{$alert->public_id}/cancel", [
            'donor_id' => $donor->id,
            'cancel_reason' => 'Tôi thấy không đủ sức khỏe để di chuyển.',
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled')
            ->assertJsonPath('data.cancel_reason', 'Tôi thấy không đủ sức khỏe để di chuyển.');

        $this->assertDatabaseHas('emergency_commitments', [
            'emergency_alert_id' => $alert->id,
            'donor_id' => $donor->id,
            'status' => 'cancelled',
            'cancel_reason' => 'Tôi thấy không đủ sức khỏe để di chuyển.',
        ]);
    }

    public function test_mobile_cannot_cancel_donated_sos_commitment(): void
    {
        Event::fake();
        $this->seed();

        $alert = EmergencyAlert::query()->where('status', 'active')->firstOrFail();
        $donor = User::query()->where('role', 'donor')->whereNotNull('latitude')->firstOrFail();

        $this->postJson("/api/mobile/sos-alerts/{$alert->public_id}/commit", [
            'donor_id' => $donor->id,
            'eta_minutes' => 12,
        ])->assertOk();

        $commitment = $alert->commitments()
            ->where('donor_id', $donor->id)
            ->firstOrFail();
        $commitment->update(['status' => 'donated']);

        $this->postJson("/api/mobile/sos-alerts/{$alert->public_id}/cancel", [
            'donor_id' => $donor->id,
            'cancel_reason' => 'Không thể đi.',
        ])->assertStatus(409);
    }
}
