<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('emergency_commitments')
            ->where('status', 'arrived')
            ->update([
                'status' => 'donated',
                'donation_volume_ml' => DB::raw('COALESCE(donation_volume_ml, 350)'),
                'donated_at' => DB::raw('COALESCE(donated_at, updated_at)'),
                'verified_at' => DB::raw('COALESCE(verified_at, updated_at)'),
            ]);

        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE emergency_commitments MODIFY status ENUM('committed','en_route','donated','cancelled') NOT NULL DEFAULT 'committed'");
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE emergency_commitments MODIFY status ENUM('committed','en_route','arrived','donated','cancelled') NOT NULL DEFAULT 'committed'");
        }
    }
};
