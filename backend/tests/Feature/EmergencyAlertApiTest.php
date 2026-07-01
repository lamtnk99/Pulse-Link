<?php

namespace Tests\Feature;

use App\Models\EmergencyAlert;
use App\Models\Hospital;
use App\Services\Contracts\EmergencyAlertRealtimeGateway;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
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
}
