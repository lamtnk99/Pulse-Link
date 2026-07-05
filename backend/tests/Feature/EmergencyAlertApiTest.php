<?php

namespace Tests\Feature;

use App\Models\EmergencyAlert;
use App\Models\EmergencyCommitment;
use App\Models\Hospital;
use App\Models\User;
use App\Services\Contracts\EmergencyAlertRealtimeGateway;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Str;
use Tests\TestCase;

class EmergencyAlertApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_hospital_can_activate_sos_alert_and_dispatch_recipients(): void
    {
        Event::fake();
        $fakeRealtimeGateway = new class implements EmergencyAlertRealtimeGateway
        {
            public int $published = 0;

            public function publish(EmergencyAlert $alert): void
            {
                $this->published++;
            }
        };
        $this->app->instance(EmergencyAlertRealtimeGateway::class, $fakeRealtimeGateway);

        $this->seed();

        $hospital = Hospital::query()->firstOrFail();

        $response = $this->postJson('/api/admin/emergency-alerts', [
            'hospital_id' => $hospital->id,
            'required_blood_type' => 'O+',
            'level' => 'level3',
            'units_needed' => 6,
            'message' => 'Bao dong do thieu mau O+ cho ca cap cuu.',
            'expires_at' => now()->addMinutes(45)->toIso8601String(),
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.required_blood_type', 'O+')
            ->assertJsonPath('data.status', 'active');

        $this->assertDatabaseHas('emergency_alert_recipients', [
            'wave' => 'local5km',
        ]);
        $this->assertSame(1, $fakeRealtimeGateway->published);
    }

    public function test_hospital_can_run_multiple_active_sos_alerts(): void
    {
        Event::fake();
        $fakeRealtimeGateway = new class implements EmergencyAlertRealtimeGateway
        {
            public int $published = 0;

            public function publish(EmergencyAlert $alert): void
            {
                $this->published++;
            }
        };
        $this->app->instance(EmergencyAlertRealtimeGateway::class, $fakeRealtimeGateway);

        $this->seed();

        $hospital = Hospital::query()->firstOrFail();
        $initialActiveAlerts = EmergencyAlert::query()
            ->where('hospital_id', $hospital->id)
            ->where('status', 'active')
            ->count();

        foreach (['O+', 'A+'] as $index => $bloodType) {
            $this->postJson('/api/admin/emergency-alerts', [
                'hospital_id' => $hospital->id,
                'required_blood_type' => $bloodType,
                'level' => 'level3',
                'units_needed' => 4 + $index,
                'message' => "Bao dong do thu {$index} cho ca cap cuu.",
                'expires_at' => now()->addMinutes(45 + $index)->toIso8601String(),
            ])->assertCreated();
        }

        $this->assertSame(2, $fakeRealtimeGateway->published);
        $this->assertSame($initialActiveAlerts + 2, EmergencyAlert::query()
            ->where('hospital_id', $hospital->id)
            ->where('status', 'active')
            ->count());

        $this->getJson("/api/admin/dashboard?hospital_id={$hospital->id}")
            ->assertOk()
            ->assertJsonPath('data.stats.active_alerts', $initialActiveAlerts + 2)
            ->assertJsonCount($initialActiveAlerts + 2, 'data.alerts');
    }

    public function test_hospital_staff_can_only_view_sos_alerts_for_their_hospital(): void
    {
        Event::fake();
        $fakeRealtimeGateway = new class implements EmergencyAlertRealtimeGateway
        {
            public function publish(EmergencyAlert $alert): void
            {
                //
            }
        };
        $this->app->instance(EmergencyAlertRealtimeGateway::class, $fakeRealtimeGateway);

        $this->seed();

        $systemAdmin = User::query()->where('email', 'system@pulselink.test')->firstOrFail();
        $choRayStaff = User::query()->where('email', 'admin@pulselink.test')->firstOrFail();
        $bachMai = Hospital::query()->where('code', 'BM-01')->firstOrFail();

        $alertId = $this->postJson("/api/admin/emergency-alerts?admin_user_id={$systemAdmin->id}", [
            'hospital_id' => $bachMai->id,
            'required_blood_type' => 'A+',
            'level' => 'level3',
            'units_needed' => 5,
            'message' => 'Bao dong do thieu mau A+ tai Bach Mai.',
            'expires_at' => now()->addMinutes(45)->toIso8601String(),
        ])
            ->assertCreated()
            ->json('data.id');

        $this->getJson("/api/admin/dashboard?admin_user_id={$choRayStaff->id}")
            ->assertOk()
            ->assertJsonMissing(['id' => $alertId]);

        $this->getJson("/api/admin/emergency-alerts/{$alertId}?admin_user_id={$choRayStaff->id}")
            ->assertForbidden();

        $this->postJson("/api/admin/emergency-alerts/{$alertId}/cancel?admin_user_id={$choRayStaff->id}")
            ->assertForbidden();
    }

    public function test_admin_can_verify_emergency_donation_and_complete_alert(): void
    {
        Event::fake();
        $fakeRealtimeGateway = new class implements EmergencyAlertRealtimeGateway
        {
            public int $published = 0;

            public function publish(EmergencyAlert $alert): void
            {
                $this->published++;
            }
        };
        $this->app->instance(EmergencyAlertRealtimeGateway::class, $fakeRealtimeGateway);

        $this->seed();

        $staff = User::query()->where('email', 'admin@pulselink.test')->firstOrFail();
        $hospital = Hospital::query()->where('code', 'CR-79')->firstOrFail();
        $donor = User::query()
            ->where('role', 'donor')
            ->where('blood_type', 'O+')
            ->firstOrFail();
        app(\App\Services\Donations\DonationRecognitionService::class)->refreshDonorRecognition($donor);
        $donor->refresh();
        $initialDonations = $donor->total_donations;
        $initialPoints = $donor->points;

        $alertId = $this->postJson("/api/admin/emergency-alerts?admin_user_id={$staff->id}", [
            'hospital_id' => $hospital->id,
            'required_blood_type' => 'O+',
            'level' => 'level3',
            'units_needed' => 4,
            'message' => 'Bao dong do xac nhan hien mau thanh cong.',
            'expires_at' => now()->addMinutes(45)->toIso8601String(),
        ])
            ->assertCreated()
            ->json('data.id');

        $this->postJson("/api/mobile/sos-alerts/{$alertId}/commit", [
            'donor_id' => $donor->id,
            'eta_minutes' => 12,
        ])->assertOk();

        $commitment = EmergencyCommitment::query()
            ->whereHas('alert', fn ($query) => $query->where('public_id', $alertId))
            ->where('donor_id', $donor->id)
            ->firstOrFail();

        $this->postJson("/api/admin/emergency-alerts/{$alertId}/commitments/{$commitment->id}/donated?admin_user_id={$staff->id}", [
            'volume_ml' => 450,
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'donated')
            ->assertJsonPath('data.donation_volume_ml', 450);

        $this->assertDatabaseHas('donation_histories', [
            'user_id' => $donor->id,
            'hospital_id' => $hospital->id,
            'certificate_id' => 'SOS-'.$commitment->emergency_alert_id.'-'.$commitment->id,
            'volume_ml' => 450,
            'status' => 'verified',
        ]);
        $donor->refresh();
        $this->assertSame($initialDonations + 1, $donor->total_donations);
        $this->assertSame($initialPoints + 630, $donor->points);

        $this->postJson("/api/admin/emergency-alerts/{$alertId}/complete?admin_user_id={$staff->id}")
            ->assertOk()
            ->assertJsonPath('data.status', 'fulfilled');

        $this->assertDatabaseHas('emergency_alerts', [
            'public_id' => $alertId,
            'status' => 'fulfilled',
        ]);
        $this->assertGreaterThanOrEqual(2, $fakeRealtimeGateway->published);
    }

    public function test_mobile_can_poll_active_compatible_sos_alerts(): void
    {
        $this->seed();

        $donor = User::query()
            ->where('role', 'donor')
            ->where('blood_type', 'O+')
            ->firstOrFail();
        $hospital = Hospital::query()->where('code', 'VT-31')->firstOrFail();

        $compatibleAlert = EmergencyAlert::query()->create([
            'public_id' => (string) Str::uuid(),
            'hospital_id' => $hospital->id,
            'required_blood_type' => 'A+',
            'level' => 'level1',
            'units_needed' => 4,
            'status' => 'active',
            'message' => 'Can ho tro mau A+ tai Viet Tiep.',
            'expires_at' => now()->addMinutes(45),
        ]);
        $incompatibleAlert = EmergencyAlert::query()->create([
            'public_id' => (string) Str::uuid(),
            'hospital_id' => $hospital->id,
            'required_blood_type' => 'O-',
            'level' => 'level1',
            'units_needed' => 4,
            'status' => 'active',
            'message' => 'Can ho tro mau O- tai Viet Tiep.',
            'expires_at' => now()->addMinutes(45),
        ]);

        $this->getJson("/api/mobile/sos-alerts?user_id={$donor->id}")
            ->assertOk()
            ->assertJsonFragment([
                'id' => $compatibleAlert->public_id,
                'active' => true,
                'hospital_name' => 'Bệnh viện Hữu nghị Việt Tiệp',
            ])
            ->assertJsonMissing([
                'id' => $incompatibleAlert->public_id,
            ]);
    }

    public function test_sos_is_fulfilled_only_after_required_donations_and_late_commit_is_soft_blocked(): void
    {
        Event::fake();
        $fakeRealtimeGateway = new class implements EmergencyAlertRealtimeGateway
        {
            public int $published = 0;

            public function publish(EmergencyAlert $alert): void
            {
                $this->published++;
            }
        };
        $this->app->instance(EmergencyAlertRealtimeGateway::class, $fakeRealtimeGateway);

        $this->seed();

        $staff = User::query()->where('email', 'admin@pulselink.test')->firstOrFail();
        $hospital = Hospital::query()->where('code', 'CR-79')->firstOrFail();
        $donors = User::query()
            ->where('role', 'donor')
            ->where('blood_type', 'O+')
            ->take(3)
            ->get();

        $alertId = $this->postJson("/api/admin/emergency-alerts?admin_user_id={$staff->id}", [
            'hospital_id' => $hospital->id,
            'required_blood_type' => 'O+',
            'level' => 'level1',
            'units_needed' => 1,
            'message' => 'Can mot don vi mau O+ cho ca cap cuu.',
            'expires_at' => now()->addMinutes(45)->toIso8601String(),
        ])->assertCreated()->json('data.id');

        foreach ($donors->take(2) as $donor) {
            $this->postJson("/api/mobile/sos-alerts/{$alertId}/commit", [
                'donor_id' => $donor->id,
                'eta_minutes' => 10,
            ])->assertOk();
        }

        $firstCommitment = EmergencyCommitment::query()
            ->whereHas('alert', fn ($query) => $query->where('public_id', $alertId))
            ->where('donor_id', $donors[0]->id)
            ->firstOrFail();

        $this->postJson("/api/admin/emergency-alerts/{$alertId}/commitments/{$firstCommitment->id}/donated?admin_user_id={$staff->id}", [
            'volume_ml' => 350,
        ])->assertOk();

        $this->assertDatabaseHas('emergency_alerts', [
            'public_id' => $alertId,
            'status' => 'fulfilled',
        ]);
        $this->assertDatabaseHas('emergency_commitments', [
            'donor_id' => $donors[1]->id,
            'status' => 'not_needed',
        ]);
        $this->assertDatabaseHas('mobile_notifications', [
            'user_id' => $donors[1]->id,
            'type' => 'sos_fulfilled',
        ]);

        $this->postJson("/api/mobile/sos-alerts/{$alertId}/commit", [
            'donor_id' => $donors[2]->id,
            'eta_minutes' => 20,
        ])->assertStatus(409)
            ->assertJsonPath('message', 'Cảm ơn bạn, ca hiến máu này đã nhận đủ đơn vị máu cần thiết. Hệ thống đã lưu ghi nhận và xin hẹn bạn ở lượt tiếp theo nhé!');
    }

    public function test_admin_can_publish_blood_journey_for_sos_donation(): void
    {
        Event::fake();
        $this->seed();

        $staff = User::query()->where('email', 'admin@pulselink.test')->firstOrFail();
        $hospital = Hospital::query()->where('code', 'CR-79')->firstOrFail();
        $donor = User::query()
            ->where('role', 'donor')
            ->where('blood_type', 'O+')
            ->firstOrFail();

        $alertId = $this->postJson("/api/admin/emergency-alerts?admin_user_id={$staff->id}", [
            'hospital_id' => $hospital->id,
            'required_blood_type' => 'O+',
            'level' => 'level1',
            'units_needed' => 2,
            'message' => 'Can mau O+ cho hanh trinh mau.',
            'expires_at' => now()->addMinutes(45)->toIso8601String(),
        ])->assertCreated()->json('data.id');

        $this->postJson("/api/mobile/sos-alerts/{$alertId}/commit", [
            'donor_id' => $donor->id,
            'eta_minutes' => 10,
        ])->assertOk();

        $commitment = EmergencyCommitment::query()
            ->whereHas('alert', fn ($query) => $query->where('public_id', $alertId))
            ->where('donor_id', $donor->id)
            ->firstOrFail();

        $this->postJson("/api/admin/emergency-alerts/{$alertId}/commitments/{$commitment->id}/donated?admin_user_id={$staff->id}", [
            'volume_ml' => 350,
        ])->assertOk();

        $this->postJson("/api/admin/emergency-alerts/{$alertId}/commitments/{$commitment->id}/journey?admin_user_id={$staff->id}", [
            'destination_type' => 'reserve',
            'current_step' => 'stored',
            'location_label' => 'Kho máu bệnh viện',
            'publish' => true,
        ])
            ->assertOk()
            ->assertJsonPath('data.destination_type', 'reserve')
            ->assertJsonPath('data.current_step', 'stored');

        $this->assertDatabaseHas('mobile_notifications', [
            'user_id' => $donor->id,
            'type' => 'blood_journey_completed',
        ]);
    }
}
