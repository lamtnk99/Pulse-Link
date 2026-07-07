<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('emergency_alerts', function (Blueprint $table) {
            $table->string('compatibility_mode', 20)
                ->default('compatible')
                ->after('required_blood_type')
                ->index();
            $table->timestamp('broadcast_stopped_at')
                ->nullable()
                ->after('expires_at')
                ->index();
        });
    }

    public function down(): void
    {
        Schema::table('emergency_alerts', function (Blueprint $table) {
            $table->dropColumn(['compatibility_mode', 'broadcast_stopped_at']);
        });
    }
};
