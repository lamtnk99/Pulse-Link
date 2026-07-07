<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Bổ sung thông tin định danh người hiến máu + luồng xác thực CCCD.
 * Thông tin người hiến cần chính xác nên có bước admin duyệt căn cước.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->date('date_of_birth')->nullable()->after('phone');
            $table->string('gender')->nullable()->after('date_of_birth');
            $table->string('address')->nullable()->after('gender');
            $table->string('national_id', 12)->nullable()->after('address');
            $table->string('id_card_front_url')->nullable()->after('national_id');
            $table->string('id_card_back_url')->nullable()->after('id_card_front_url');
            // unverified | pending | verified | rejected
            $table->string('id_verification_status')->default('unverified')->after('id_card_back_url');
            $table->timestamp('id_verified_at')->nullable()->after('id_verification_status');
            $table->string('id_rejection_reason')->nullable()->after('id_verified_at');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'date_of_birth',
                'gender',
                'address',
                'national_id',
                'id_card_front_url',
                'id_card_back_url',
                'id_verification_status',
                'id_verified_at',
                'id_rejection_reason',
            ]);
        });
    }
};
