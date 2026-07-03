<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('emergency_commitments', function (Blueprint $table) {
            if (! Schema::hasColumn('emergency_commitments', 'cancel_reason')) {
                $table->text('cancel_reason')->nullable()->after('status');
            }
        });
    }

    public function down(): void
    {
        Schema::table('emergency_commitments', function (Blueprint $table) {
            if (Schema::hasColumn('emergency_commitments', 'cancel_reason')) {
                $table->dropColumn('cancel_reason');
            }
        });
    }
};
