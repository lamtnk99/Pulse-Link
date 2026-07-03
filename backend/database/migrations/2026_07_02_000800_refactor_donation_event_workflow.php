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
            DB::statement("ALTER TABLE donation_appointments MODIFY status ENUM('booked','cancelled','checked_in','deferred','completed','no_show') NOT NULL DEFAULT 'booked'");
        }

        Schema::table('donation_events', function (Blueprint $table) {
            if (! Schema::hasColumn('donation_events', 'cancelled_at')) {
                $table->timestamp('cancelled_at')->nullable()->after('is_published')->index();
            }
            if (! Schema::hasColumn('donation_events', 'cancel_reason')) {
                $table->text('cancel_reason')->nullable()->after('cancelled_at');
            }
        });

        Schema::table('donation_appointments', function (Blueprint $table) {
            if (! Schema::hasColumn('donation_appointments', 'checked_in_at')) {
                $table->timestamp('checked_in_at')->nullable()->after('booked_at');
            }
            if (! Schema::hasColumn('donation_appointments', 'cancelled_at')) {
                $table->timestamp('cancelled_at')->nullable()->after('checked_in_at');
            }
            if (! Schema::hasColumn('donation_appointments', 'cancel_reason')) {
                $table->text('cancel_reason')->nullable()->after('cancelled_at');
            }
            if (! Schema::hasColumn('donation_appointments', 'completed_at')) {
                $table->timestamp('completed_at')->nullable()->after('cancel_reason');
            }
            if (! Schema::hasColumn('donation_appointments', 'no_show_at')) {
                $table->timestamp('no_show_at')->nullable()->after('completed_at');
            }
            if (! Schema::hasColumn('donation_appointments', 'volume_ml')) {
                $table->unsignedSmallInteger('volume_ml')->nullable()->after('no_show_at');
            }
            if (! Schema::hasColumn('donation_appointments', 'screening_status')) {
                $table->string('screening_status')->nullable()->after('volume_ml')->index();
            }
            if (! Schema::hasColumn('donation_appointments', 'screening_notes')) {
                $table->text('screening_notes')->nullable()->after('screening_status');
            }
            if (! Schema::hasColumn('donation_appointments', 'result_summary')) {
                $table->text('result_summary')->nullable()->after('screening_notes');
            }
            if (! Schema::hasColumn('donation_appointments', 'result_published_at')) {
                $table->timestamp('result_published_at')->nullable()->after('result_summary');
            }
        });

        Schema::table('donation_histories', function (Blueprint $table) {
            if (! Schema::hasColumn('donation_histories', 'donation_appointment_id')) {
                if (DB::getDriverName() === 'sqlite') {
                    $table->unsignedBigInteger('donation_appointment_id')->nullable()->after('user_id');
                } else {
                    $table->foreignId('donation_appointment_id')
                        ->nullable()
                        ->after('user_id')
                        ->references('id')
                        ->on('donation_appointments')
                        ->nullOnDelete();
                }

                $table->unique('donation_appointment_id');
            }
        });
    }

    public function down(): void
    {
        Schema::table('donation_histories', function (Blueprint $table) {
            if (Schema::hasColumn('donation_histories', 'donation_appointment_id')) {
                $table->dropUnique(['donation_appointment_id']);

                if (DB::getDriverName() === 'sqlite') {
                    $table->dropColumn('donation_appointment_id');
                } else {
                    $table->dropConstrainedForeignId('donation_appointment_id');
                }
            }
        });

        Schema::table('donation_appointments', function (Blueprint $table) {
            foreach ([
                'result_published_at',
                'result_summary',
                'screening_notes',
                'screening_status',
                'volume_ml',
                'no_show_at',
                'completed_at',
                'cancel_reason',
                'cancelled_at',
                'checked_in_at',
            ] as $column) {
                if (Schema::hasColumn('donation_appointments', $column)) {
                    $table->dropColumn($column);
                }
            }
        });

        Schema::table('donation_events', function (Blueprint $table) {
            foreach (['cancel_reason', 'cancelled_at'] as $column) {
                if (Schema::hasColumn('donation_events', $column)) {
                    $table->dropColumn($column);
                }
            }
        });

        if (DB::getDriverName() === 'mysql') {
            DB::table('donation_appointments')
                ->whereIn('status', ['checked_in', 'deferred'])
                ->update(['status' => 'booked']);
            DB::statement("ALTER TABLE donation_appointments MODIFY status ENUM('booked','cancelled','completed','no_show') NOT NULL DEFAULT 'booked'");
        }
    }
};
