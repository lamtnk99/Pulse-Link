<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('donation_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('hospital_id')->nullable()->constrained()->nullOnDelete();
            $table->string('title');
            $table->string('organizer');
            $table->dateTime('starts_at')->index();
            $table->dateTime('ends_at')->index();
            $table->string('location_name');
            $table->string('province_code', 2)->nullable()->index();
            $table->string('ward_code', 5)->nullable()->index();
            $table->decimal('latitude', 10, 7)->index();
            $table->decimal('longitude', 10, 7)->index();
            $table->enum('urgency', ['normal', 'high'])->default('normal')->index();
            $table->string('image_url')->nullable();
            $table->unsignedInteger('capacity')->default(0);
            $table->unsignedInteger('booked_count')->default(0);
            $table->boolean('is_published')->default(true)->index();
            $table->timestamp('cancelled_at')->nullable()->index();
            $table->text('cancel_reason')->nullable();
            $table->timestamps();
        });

        Schema::create('donation_appointments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('donation_event_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->enum('status', ['booked', 'cancelled', 'checked_in', 'deferred', 'completed', 'no_show'])
                ->default('booked')
                ->index();
            $table->timestamp('booked_at')->nullable();
            $table->timestamp('checked_in_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->text('cancel_reason')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('no_show_at')->nullable();
            $table->unsignedSmallInteger('volume_ml')->nullable();
            $table->string('screening_status')->nullable()->index();
            $table->text('screening_notes')->nullable();
            $table->text('result_summary')->nullable();
            $table->timestamp('result_published_at')->nullable();
            $table->timestamps();

            $table->unique(['donation_event_id', 'user_id']);
        });

        Schema::create('donation_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('donation_appointment_id')->nullable()->unique()->constrained()->nullOnDelete();
            $table->foreignId('hospital_id')->nullable()->constrained()->nullOnDelete();
            $table->date('donated_at')->index();
            $table->string('location_name');
            $table->unsignedSmallInteger('volume_ml');
            $table->string('blood_type', 4)->index();
            $table->string('certificate_id')->unique();
            $table->enum('status', ['pending', 'verified'])->default('pending')->index();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('donation_histories');
        Schema::dropIfExists('donation_appointments');
        Schema::dropIfExists('donation_events');
    }
};
