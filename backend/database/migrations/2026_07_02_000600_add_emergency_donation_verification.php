<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE emergency_commitments MODIFY status ENUM('committed','en_route','donated','cancelled') NOT NULL DEFAULT 'committed'");
        }

        Schema::table('emergency_commitments', function (Blueprint $table) {
            if (! Schema::hasColumn('emergency_commitments', 'donation_volume_ml')) {
                $table->unsignedSmallInteger('donation_volume_ml')->nullable()->after('eta_minutes');
            }
            if (! Schema::hasColumn('emergency_commitments', 'donated_at')) {
                $table->timestamp('donated_at')->nullable()->after('last_location_at');
            }
            if (! Schema::hasColumn('emergency_commitments', 'verified_at')) {
                $table->timestamp('verified_at')->nullable()->after('donated_at');
            }
            if (! Schema::hasColumn('emergency_commitments', 'verified_by')) {
                $table->foreignId('verified_by')->nullable()->after('verified_at')->references('id')->on('users')->nullOnDelete();
            }
            if (! Schema::hasColumn('emergency_commitments', 'donation_history_id')) {
                $table->foreignId('donation_history_id')->nullable()->after('verified_by')->references('id')->on('donation_histories')->nullOnDelete();
            }
        });
    }

    public function down(): void
    {
        Schema::table('emergency_commitments', function (Blueprint $table) {
            foreach (['donation_history_id', 'verified_by'] as $column) {
                if (Schema::hasColumn('emergency_commitments', $column)) {
                    $table->dropConstrainedForeignId($column);
                }
            }

            foreach (['verified_at', 'donated_at', 'donation_volume_ml'] as $column) {
                if (Schema::hasColumn('emergency_commitments', $column)) {
                    $table->dropColumn($column);
                }
            }
        });

        if (DB::getDriverName() === 'mysql') {
            DB::table('emergency_commitments')
                ->where('status', 'donated')
                ->update(['status' => 'en_route']);
            DB::statement("ALTER TABLE emergency_commitments MODIFY status ENUM('committed','en_route','arrived','cancelled') NOT NULL DEFAULT 'committed'");
        }
    }
};
