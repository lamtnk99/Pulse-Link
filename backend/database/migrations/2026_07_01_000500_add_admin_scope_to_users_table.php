<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('hospital_id')
                ->nullable()
                ->after('role')
                ->constrained()
                ->nullOnDelete();
            $table->json('permissions')->nullable()->after('hospital_id');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('hospital_id');
            $table->dropColumn('permissions');
        });
    }
};
