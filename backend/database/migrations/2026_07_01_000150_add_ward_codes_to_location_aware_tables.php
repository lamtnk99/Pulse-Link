<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('ward_code', 5)->nullable()->after('province_code')->index();
        });

        Schema::table('hospitals', function (Blueprint $table) {
            $table->string('ward_code', 5)->nullable()->after('province_code')->index();
        });

    }

    public function down(): void
    {
        Schema::table('hospitals', function (Blueprint $table) {
            $table->dropColumn('ward_code');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('ward_code');
        });
    }
};
