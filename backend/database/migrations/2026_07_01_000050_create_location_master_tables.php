<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('administrative_regions', function (Blueprint $table) {
            $table->id();
            $table->string('code', 32)->unique();
            $table->string('name');
            $table->string('name_en')->nullable();
            $table->timestamps();
        });

        Schema::create('administrative_units', function (Blueprint $table) {
            $table->unsignedSmallInteger('id')->primary();
            $table->string('short_name');
            $table->string('full_name');
            $table->string('short_name_en')->nullable();
            $table->string('full_name_en')->nullable();
            $table->timestamps();
        });

        Schema::create('provinces', function (Blueprint $table) {
            $table->string('code', 2)->primary();
            $table->string('name');
            $table->string('name_en')->nullable();
            $table->string('full_name');
            $table->string('full_name_en')->nullable();
            $table->string('code_name')->index();
            $table->unsignedSmallInteger('administrative_unit_id')->nullable();
            $table->foreign('administrative_unit_id')->references('id')->on('administrative_units')->nullOnDelete();
            $table->string('region_code', 32)->nullable()->index();
            $table->decimal('centroid_latitude', 10, 7)->nullable();
            $table->decimal('centroid_longitude', 10, 7)->nullable();
            $table->boolean('is_active')->default(true)->index();
            $table->timestamps();
        });

        Schema::create('wards', function (Blueprint $table) {
            $table->string('code', 5)->primary();
            $table->string('province_code', 2)->index();
            $table->string('name');
            $table->string('name_en')->nullable();
            $table->string('full_name');
            $table->string('full_name_en')->nullable();
            $table->string('code_name')->index();
            $table->unsignedSmallInteger('administrative_unit_id')->nullable();
            $table->foreign('province_code')->references('code')->on('provinces')->cascadeOnDelete();
            $table->foreign('administrative_unit_id')->references('id')->on('administrative_units')->nullOnDelete();
            $table->boolean('is_active')->default(true)->index();
            $table->timestamps();
        });

        Schema::create('province_aliases', function (Blueprint $table) {
            $table->id();
            $table->string('alias')->unique();
            $table->string('normalized_alias')->index();
            $table->string('province_code', 2)->index();
            $table->string('note')->nullable();
            $table->foreign('province_code')->references('code')->on('provinces')->cascadeOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('province_aliases');
        Schema::dropIfExists('wards');
        Schema::dropIfExists('provinces');
        Schema::dropIfExists('administrative_units');
        Schema::dropIfExists('administrative_regions');
    }
};
