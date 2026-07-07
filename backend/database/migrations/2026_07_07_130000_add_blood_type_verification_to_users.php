<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('blood_type_verification_status')
                ->default('unreported')
                ->after('blood_type');
            $table->timestamp('blood_type_verified_at')->nullable()->after('blood_type_verification_status');
            $table->foreignId('blood_type_verified_by')->nullable()->after('blood_type_verified_at')->constrained('users')->nullOnDelete();
            $table->foreignId('blood_type_verified_hospital_id')->nullable()->after('blood_type_verified_by')->constrained('hospitals')->nullOnDelete();
            $table->foreignId('blood_type_verified_donation_history_id')->nullable()->after('blood_type_verified_hospital_id')->constrained('donation_histories')->nullOnDelete();
        });

        DB::table('users')
            ->whereNotNull('blood_type')
            ->update(['blood_type_verification_status' => 'self_reported']);

        DB::table('users')
            ->whereExists(function ($query): void {
                $query->select(DB::raw(1))
                    ->from('donation_histories')
                    ->whereColumn('donation_histories.user_id', 'users.id')
                    ->where('donation_histories.status', 'verified');
            })
            ->update([
                'blood_type_verification_status' => 'verified',
                'blood_type_verified_at' => now(),
            ]);
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('blood_type_verified_donation_history_id');
            $table->dropConstrainedForeignId('blood_type_verified_hospital_id');
            $table->dropConstrainedForeignId('blood_type_verified_by');
            $table->dropColumn([
                'blood_type_verified_at',
                'blood_type_verification_status',
            ]);
        });
    }
};
