<?php

namespace Tests\Feature;

use App\Models\CommunityPost;
use App\Models\DonationEvent;
use App\Models\EmergencyAlert;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
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
            ->assertJsonPath('data.status', 'committed');

        $this->assertDatabaseHas('emergency_commitments', [
            'emergency_alert_id' => $alert->id,
            'donor_id' => $donor->id,
            'eta_minutes' => 12,
        ]);
    }
}
