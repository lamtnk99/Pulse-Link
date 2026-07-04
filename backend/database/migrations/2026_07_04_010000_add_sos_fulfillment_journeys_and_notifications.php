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
            DB::statement("ALTER TABLE emergency_commitments MODIFY status ENUM('committed','en_route','donated','cancelled','not_needed') NOT NULL DEFAULT 'committed'");
        }

        Schema::create('blood_journeys', function (Blueprint $table) {
            $table->id();
            $table->uuid('public_id')->unique();
            $table->foreignId('emergency_alert_id')->constrained()->cascadeOnDelete();
            $table->foreignId('emergency_commitment_id')->constrained()->cascadeOnDelete();
            $table->foreignId('donation_history_id')->constrained()->cascadeOnDelete();
            $table->foreignId('donor_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreignId('hospital_id')->constrained()->cascadeOnDelete();
            $table->enum('destination_type', ['patient', 'reserve'])->default('patient')->index();
            $table->string('current_step')->default('received')->index();
            $table->string('location_label')->nullable();
            $table->text('final_message')->nullable();
            $table->timestamp('published_at')->nullable()->index();
            $table->timestamp('completed_at')->nullable()->index();
            $table->timestamps();

            $table->unique('emergency_commitment_id');
            $table->unique('donation_history_id');
        });

        Schema::create('blood_journey_steps', function (Blueprint $table) {
            $table->id();
            $table->foreignId('blood_journey_id')->constrained()->cascadeOnDelete();
            $table->string('step_key')->index();
            $table->string('label');
            $table->text('message')->nullable();
            $table->unsignedTinyInteger('sort_order')->default(1);
            $table->timestamp('occurred_at')->nullable();
            $table->timestamps();

            $table->unique(['blood_journey_id', 'step_key']);
        });

        Schema::create('mobile_notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type')->index();
            $table->string('title');
            $table->text('body');
            $table->json('payload')->nullable();
            $table->timestamp('read_at')->nullable()->index();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mobile_notifications');
        Schema::dropIfExists('blood_journey_steps');
        Schema::dropIfExists('blood_journeys');

        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE emergency_commitments MODIFY status ENUM('committed','en_route','donated','cancelled') NOT NULL DEFAULT 'committed'");
        }
    }
};
