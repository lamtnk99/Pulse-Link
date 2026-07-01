<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('emergency_alerts', function (Blueprint $table) {
            $table->id();
            $table->uuid('public_id')->unique();
            $table->foreignId('hospital_id')->constrained()->cascadeOnDelete();
            $table->foreignId('created_by')->nullable()->references('id')->on('users')->nullOnDelete();
            $table->string('required_blood_type', 4)->index();
            $table->enum('level', ['level1', 'level2', 'level3'])->index();
            $table->unsignedSmallInteger('units_needed');
            $table->enum('status', ['draft', 'active', 'fulfilled', 'expired', 'cancelled'])
                ->default('active')
                ->index();
            $table->text('message');
            $table->dateTime('expires_at')->index();
            $table->json('dispatch_summary')->nullable();
            $table->timestamps();
        });

        Schema::create('emergency_alert_recipients', function (Blueprint $table) {
            $table->id();
            $table->foreignId('emergency_alert_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->enum('wave', ['local5km', 'province30km', 'inter_province'])->index();
            $table->decimal('distance_km', 8, 3);
            $table->timestamp('notified_at')->nullable();
            $table->timestamp('acknowledged_at')->nullable();
            $table->timestamps();

            $table->unique(['emergency_alert_id', 'user_id']);
        });

        Schema::create('emergency_commitments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('emergency_alert_id')->constrained()->cascadeOnDelete();
            $table->foreignId('donor_id')->references('id')->on('users')->cascadeOnDelete();
            $table->enum('status', ['committed', 'en_route', 'arrived', 'cancelled'])
                ->default('committed')
                ->index();
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->unsignedSmallInteger('eta_minutes')->nullable();
            $table->timestamp('committed_at')->nullable();
            $table->timestamp('last_location_at')->nullable();
            $table->timestamps();

            $table->unique(['emergency_alert_id', 'donor_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('emergency_commitments');
        Schema::dropIfExists('emergency_alert_recipients');
        Schema::dropIfExists('emergency_alerts');
    }
};
