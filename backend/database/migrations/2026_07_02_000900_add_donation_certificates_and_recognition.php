<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('donation_histories', function (Blueprint $table) {
            if (! Schema::hasColumn('donation_histories', 'donation_type')) {
                $table->string('donation_type', 24)->default('regular')->after('hospital_id')->index();
            }
            if (! Schema::hasColumn('donation_histories', 'certificate_title')) {
                $table->string('certificate_title')->nullable()->after('certificate_id');
            }
            if (! Schema::hasColumn('donation_histories', 'certificate_issued_at')) {
                $table->timestamp('certificate_issued_at')->nullable()->after('certificate_title');
            }
            if (! Schema::hasColumn('donation_histories', 'certificate_verify_token')) {
                $table->string('certificate_verify_token', 64)->nullable()->unique()->after('certificate_issued_at');
            }
        });
    }

    public function down(): void
    {
        Schema::table('donation_histories', function (Blueprint $table) {
            foreach ([
                'certificate_verify_token',
                'certificate_issued_at',
                'certificate_title',
                'donation_type',
            ] as $column) {
                if (Schema::hasColumn('donation_histories', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
