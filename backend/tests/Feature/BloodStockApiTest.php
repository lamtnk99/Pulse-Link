<?php

namespace Tests\Feature;

use App\Models\BloodSafetyThreshold;
use App\Models\BloodStock;
use App\Models\BloodStockMovement;
use App\Models\DonationEvent;
use App\Models\ForecastRecommendation;
use App\Models\Hospital;
use App\Models\SmartAlert;
use App\Models\User;
use App\Services\AI\InventoryForecastService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BloodStockApiTest extends TestCase
{
    use RefreshDatabase;

    private Hospital $hospitalA;

    private Hospital $hospitalB;

    private User $sysAdmin;

    private User $staffA;

    protected function setUp(): void
    {
        parent::setUp();

        // Tạo bệnh viện mẫu
        $this->hospitalA = Hospital::create([
            'name' => 'Bệnh viện A',
            'code' => 'HOSP_A',
            'province_code' => '79',
            'ward_code' => '27301',
            'address' => '123 Đường A',
            'latitude' => 10.7,
            'longitude' => 106.6,
            'is_active' => true,
        ]);

        $this->hospitalB = Hospital::create([
            'name' => 'Bệnh viện B',
            'code' => 'HOSP_B',
            'province_code' => '79',
            'ward_code' => '27316',
            'address' => '456 Đường B',
            'latitude' => 10.8,
            'longitude' => 106.7,
            'is_active' => true,
        ]);

        // Tạo người dùng quản trị
        $this->sysAdmin = User::create([
            'name' => 'System Admin',
            'email' => 'admin@test.com',
            'password' => bcrypt('password'),
            'role' => 'system_admin',
        ]);

        $this->staffA = User::create([
            'name' => 'Staff A',
            'email' => 'staffa@test.com',
            'password' => bcrypt('password'),
            'role' => 'hospital_staff',
            'hospital_id' => $this->hospitalA->id,
            'permissions' => ['dashboard.view', 'posts.manage'],
        ]);
    }

    public function test_admin_can_view_blood_stocks_for_any_hospital(): void
    {
        // Tạo túi máu tồn kho
        BloodStock::create([
            'hospital_id' => $this->hospitalA->id,
            'blood_type' => 'O+',
            'volume_ml' => 350,
            'received_date' => now()->toDateString(),
            'expiry_date' => now()->addDays(35)->toDateString(),
            'status' => 'available',
        ]);

        // Gửi request dưới tư cách system admin
        $response = $this->withHeader('X-Admin-User-Id', $this->sysAdmin->id)
            ->getJson("/api/admin/blood-stocks?hospital_id={$this->hospitalA->id}");

        $response->assertOk()
            ->assertJsonPath('data.hospital_id', $this->hospitalA->id)
            ->assertJsonPath('data.stats.total_units', 1);
    }

    public function test_hospital_staff_is_scoped_to_their_own_hospital(): void
    {
        // Tạo túi máu tại Bệnh viện B
        BloodStock::create([
            'hospital_id' => $this->hospitalB->id,
            'blood_type' => 'O+',
            'volume_ml' => 350,
            'received_date' => now()->toDateString(),
            'expiry_date' => now()->addDays(35)->toDateString(),
            'status' => 'available',
        ]);

        // Gửi request dưới tư cách staffA (thuộc bệnh viện A) nhưng cố truy vấn bệnh viện B
        $response = $this->withHeader('X-Admin-User-Id', $this->staffA->id)
            ->getJson("/api/admin/blood-stocks?hospital_id={$this->hospitalB->id}");

        // Hệ thống phải tự động điều hướng và chỉ trả về dữ liệu của Bệnh viện A
        $response->assertOk()
            ->assertJsonPath('data.hospital_id', $this->hospitalA->id)
            ->assertJsonPath('data.stats.total_units', 0);
    }

    public function test_admin_can_add_blood_stock_and_resolve_scarcity_alerts(): void
    {
        // 1. Tạo ngưỡng an toàn nhóm O- là 5 túi tại BV A
        BloodSafetyThreshold::create([
            'hospital_id' => $this->hospitalA->id,
            'blood_type' => 'O-',
            'min_units' => 5,
        ]);

        // 2. Tạo 1 alert khuyết nhóm O- (đang hoạt động) do không có túi nào
        $alert = SmartAlert::create([
            'hospital_id' => $this->hospitalA->id,
            'blood_type' => 'O-',
            'current_units' => 0,
            'threshold_units' => 5,
            'status' => 'active',
            'triggered_at' => now(),
        ]);

        // 3. Admin nhập kho 6 túi O- cùng lúc (lớn hơn ngưỡng 5)
        for ($i = 0; $i < 6; $i++) {
            $this->withHeader('X-Admin-User-Id', $this->sysAdmin->id)
                ->postJson('/api/admin/blood-stocks', [
                    'hospital_id' => $this->hospitalA->id,
                    'blood_type' => 'O-',
                    'volume_ml' => 350,
                    'received_date' => now()->toDateString(),
                    'expiry_date' => now()->addDays(35)->toDateString(),
                ])
                ->assertCreated();
        }

        // 4. Alert cũ phải được tự động giải quyết (resolved)
        $this->assertEquals('resolved', $alert->fresh()->status);
        $this->assertNotNull($alert->fresh()->resolved_at);
    }

    public function test_updating_status_triggers_scarcity_alerts_if_below_threshold(): void
    {
        // 1. Tạo ngưỡng an toàn nhóm A- là 2 túi tại BV A
        BloodSafetyThreshold::create([
            'hospital_id' => $this->hospitalA->id,
            'blood_type' => 'A-',
            'min_units' => 2,
        ]);

        // 2. Tạo 2 túi A- trong kho
        $bag1 = BloodStock::create([
            'hospital_id' => $this->hospitalA->id,
            'blood_type' => 'A-',
            'volume_ml' => 350,
            'received_date' => now()->toDateString(),
            'expiry_date' => now()->addDays(35)->toDateString(),
            'status' => 'available',
        ]);

        $bag2 = BloodStock::create([
            'hospital_id' => $this->hospitalA->id,
            'blood_type' => 'A-',
            'volume_ml' => 350,
            'received_date' => now()->toDateString(),
            'expiry_date' => now()->addDays(35)->toDateString(),
            'status' => 'available',
        ]);

        // Không được có alert nào
        $this->assertFalse(SmartAlert::where('hospital_id', $this->hospitalA->id)->where('blood_type', 'A-')->exists());

        // 3. Cập nhật 1 túi thành "used" (đã dùng) -> Tồn kho giảm xuống còn 1 túi (dưới ngưỡng 2)
        $this->withHeader('X-Admin-User-Id', $this->sysAdmin->id)
            ->putJson("/api/admin/blood-stocks/{$bag1->id}/status", [
                'status' => 'used',
            ])
            ->assertOk();

        // 4. Hệ thống phải kích hoạt một alert active mới
        $alertExists = SmartAlert::where('hospital_id', $this->hospitalA->id)
            ->where('blood_type', 'A-')
            ->where('status', 'active')
            ->exists();
        $this->assertTrue($alertExists);
    }

    public function test_getting_ai_demand_forecast(): void
    {
        $response = $this->withHeader('X-Admin-User-Id', $this->sysAdmin->id)
            ->postJson('/api/admin/blood-stocks/forecast/generate', [
                'hospital_id' => $this->hospitalA->id,
            ]);

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'forecast_date',
                    'reasoning_summary',
                    'recommendations',
                    'forecast' => [
                        '*' => ['blood_type', 'predicted_volume_ml', 'confidence_score', 'explanation'],
                    ],
                    'suggested_events' => [
                        '*' => ['drive_type', 'title', 'organizer', 'description', 'location_name', 'suggested_date', 'starts_at', 'ends_at', 'urgency', 'capacity', 'hospital_id', 'province_code', 'ward_code', 'latitude', 'longitude'],
                    ],
                ],
            ]);
    }

    public function test_forecast_v2_reads_used_movements_and_returns_auditable_overview(): void
    {
        BloodSafetyThreshold::create([
            'hospital_id' => $this->hospitalA->id,
            'blood_type' => 'O+',
            'min_units' => 3,
        ]);
        for ($i = 0; $i < 5; $i++) {
            BloodStock::create([
                'hospital_id' => $this->hospitalA->id,
                'blood_type' => 'O+',
                'volume_ml' => 350,
                'received_date' => now()->subDays(5)->toDateString(),
                'expiry_date' => now()->addDays(30)->toDateString(),
                'status' => 'available',
            ]);
        }
        for ($day = 1; $day <= 35; $day++) {
            BloodStockMovement::create([
                'hospital_id' => $this->hospitalA->id,
                'blood_type' => 'O+',
                'movement_type' => 'manual_status_updated',
                'to_status' => 'used',
                'quantity_units' => $day % 7 === 0 ? 2 : 1,
                'volume_ml' => 350,
                'available_delta' => 0,
                'idempotency_key' => "test-forecast-used-{$day}",
                'occurred_at' => now()->subDays($day),
            ]);
        }

        $run = app(InventoryForecastService::class)->createRun($this->hospitalA, 'manual', [], $this->sysAdmin->id);
        app(InventoryForecastService::class)->generate($run);

        $this->withHeader('X-Admin-User-Id', $this->sysAdmin->id)
            ->getJson("/api/admin/blood-forecasts/overview?hospital_id={$this->hospitalA->id}&horizon=7")
            ->assertOk()
            ->assertJsonPath('data.run.status', 'completed')
            ->assertJsonPath('data.run.data_quality.level', 'medium')
            ->assertJsonStructure([
                'data' => [
                    'run', 'points', 'horizon_totals', 'risk_rows', 'recommendations',
                ],
            ]);

        $recommendation = ForecastRecommendation::query()
            ->where('forecast_run_id', $run->id)
            ->where('action_type', 'create_event')
            ->firstOrFail();
        $secondRecommendation = ForecastRecommendation::query()->create([
            'forecast_run_id' => $run->id,
            'hospital_id' => $this->hospitalA->id,
            'blood_type' => 'AB-',
            'action_type' => 'create_event',
            'status' => 'suggested',
            'severity' => 'high',
            'title' => 'Chuẩn bị bổ sung nhóm AB-',
            'rationale' => 'Nhóm AB- có nguy cơ xuống dưới ngưỡng an toàn.',
            'due_date' => now()->addDays(2)->toDateString(),
            'projected_gap_units' => 4,
            'payload' => ['data_quality' => 'medium'],
        ]);
        $this->withHeader('X-Admin-User-Id', $this->sysAdmin->id)
            ->postJson("/api/admin/forecast-recommendations/{$recommendation->id}/draft-event", [
                'recommendation_ids' => [$recommendation->id, $secondRecommendation->id],
            ])
            ->assertCreated()
            ->assertJsonPath('data.is_published', false)
            ->assertJsonPath('data.capacity', 120);
        $draftEvent = DonationEvent::query()->latest('id')->firstOrFail();
        $this->assertStringContainsString($recommendation->blood_type, $draftEvent->description);
        $this->assertStringContainsString('AB-', $draftEvent->description);
        $this->assertSame('draft_created', $recommendation->fresh()->status);
        $this->assertSame('draft_created', $secondRecommendation->fresh()->status);
        $this->assertSame(
            $recommendation->fresh()->payload['draft_event_id'],
            $secondRecommendation->fresh()->payload['draft_event_id'],
        );
        $this->withHeader('X-Admin-User-Id', $this->sysAdmin->id)
            ->postJson("/api/admin/forecast-recommendations/{$recommendation->id}/draft-post")
            ->assertCreated()
            ->assertJsonPath('data.status', 'draft');
    }

    public function test_console_command_marks_expired_blood_bags(): void
    {
        // 1. Tạo 1 túi máu quá hạn (hạn sử dụng từ 5 ngày trước)
        $expiredBag = BloodStock::create([
            'hospital_id' => $this->hospitalA->id,
            'blood_type' => 'O+',
            'volume_ml' => 350,
            'received_date' => now()->subDays(40)->toDateString(),
            'expiry_date' => now()->subDays(5)->toDateString(),
            'status' => 'available',
        ]);

        // 2. Chạy console command
        $this->artisan('blood-stock:check-expiry')
            ->assertExitCode(0);

        // 3. Túi máu phải chuyển trạng thái sang expired
        $this->assertEquals('expired', $expiredBag->fresh()->status);
        $this->assertDatabaseHas('blood_stock_movements', [
            'blood_stock_id' => $expiredBag->id,
            'movement_type' => 'stock_expired',
            'available_delta' => -1,
        ]);
    }
}
