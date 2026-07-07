<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('donation_events', function (Blueprint $table) {
            $table->enum('drive_type', ['in_hospital', 'mobile'])
                ->default('in_hospital')
                ->index()
                ->after('hospital_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('donation_events', function (Blueprint $table) {
            $table->dropColumn('drive_type');
        });
    }
};
