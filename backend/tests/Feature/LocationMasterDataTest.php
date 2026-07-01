<?php

namespace Tests\Feature;

use App\Models\Province;
use App\Models\Ward;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class LocationMasterDataTest extends TestCase
{
    use RefreshDatabase;

    public function test_seed_imports_current_vietnam_location_master_data(): void
    {
        $this->seed();

        $this->assertSame(34, Province::query()->count());
        $this->assertSame(3321, Ward::query()->count());

        $this->assertDatabaseHas('provinces', [
            'code' => '79',
            'name_en' => 'Ho Chi Minh',
        ]);
        $this->assertDatabaseHas('wards', [
            'code' => '27301',
            'province_code' => '79',
            'name_en' => 'Cho Quan',
        ]);
    }

    public function test_seeded_business_tables_use_official_province_codes(): void
    {
        $this->seed();

        foreach (['users', 'hospitals', 'donation_events'] as $table) {
            $legacyCount = DB::table($table)
                ->whereIn('province_code', ['HCM', 'BD', 'LA'])
                ->count();

            $this->assertSame(0, $legacyCount, "{$table} contains legacy province codes.");
        }
    }

    public function test_location_api_lists_and_normalizes_provinces(): void
    {
        $this->seed();

        $this->getJson('/api/locations/provinces')
            ->assertOk()
            ->assertJsonCount(34, 'data')
            ->assertJsonPath('data.27.code', '79');

        $this->getJson('/api/locations/provinces/79/wards')
            ->assertOk()
            ->assertJsonPath('data.0.province_code', '79');

        $this->postJson('/api/locations/normalize', ['value' => 'HCM'])
            ->assertOk()
            ->assertJsonPath('data.matched', true)
            ->assertJsonPath('data.province.code', '79');
    }
}
