<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            VietnamAdministrativeUnitSeeder::class,
            ProvinceAliasSeeder::class,
            HospitalSeeder::class,
            DonorSeeder::class,
            DailyScenarioSeeder::class,
            CommunityPostSeeder::class,
            EmergencyScenarioSeeder::class,
            DonationCampaignSeeder::class,
            BloodStockSeeder::class,
        ]);
    }
}
