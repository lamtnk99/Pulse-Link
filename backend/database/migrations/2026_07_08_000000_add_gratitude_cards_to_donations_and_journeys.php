<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('donation_histories', function (Blueprint $table): void {
            if (! Schema::hasColumn('donation_histories', 'gratitude_message')) {
                $table->text('gratitude_message')->nullable()->after('notes');
            }
            if (! Schema::hasColumn('donation_histories', 'gratitude_style')) {
                $table->string('gratitude_style', 40)->nullable()->after('gratitude_message');
            }
            if (! Schema::hasColumn('donation_histories', 'gratitude_created_at')) {
                $table->timestamp('gratitude_created_at')->nullable()->after('gratitude_style');
            }
        });

        Schema::table('blood_journeys', function (Blueprint $table): void {
            if (! Schema::hasColumn('blood_journeys', 'pulse_link_message')) {
                $table->text('pulse_link_message')->nullable()->after('final_message');
            }
            if (! Schema::hasColumn('blood_journeys', 'gratitude_style')) {
                $table->string('gratitude_style', 40)->nullable()->after('pulse_link_message');
            }
        });
    }

    public function down(): void
    {
        Schema::table('blood_journeys', function (Blueprint $table): void {
            if (Schema::hasColumn('blood_journeys', 'gratitude_style')) {
                $table->dropColumn('gratitude_style');
            }
            if (Schema::hasColumn('blood_journeys', 'pulse_link_message')) {
                $table->dropColumn('pulse_link_message');
            }
        });

        Schema::table('donation_histories', function (Blueprint $table): void {
            if (Schema::hasColumn('donation_histories', 'gratitude_created_at')) {
                $table->dropColumn('gratitude_created_at');
            }
            if (Schema::hasColumn('donation_histories', 'gratitude_style')) {
                $table->dropColumn('gratitude_style');
            }
            if (Schema::hasColumn('donation_histories', 'gratitude_message')) {
                $table->dropColumn('gratitude_message');
            }
        });
    }
};
