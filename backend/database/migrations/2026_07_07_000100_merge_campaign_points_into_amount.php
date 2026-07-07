<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Gộp cơ chế quyên góp về một trục tiền (VND) duy nhất.
 *
 * Điểm Hero vẫn góp được ở mobile nhưng quy đổi ngay ra tiền (1 điểm = 250đ)
 * và cộng vào cùng current_amount. Cột points trên campaign_donations được giữ
 * lại để ghi nhận "đã tặng X điểm Hero". Các cột 2-trục trên campaign
 * (type/target_points/current_points) không còn cần nữa.
 */
return new class extends Migration
{
    private const POINT_VALUE_VND = 250;

    public function up(): void
    {
        // 1. Backfill: các lượt góp điểm cũ (amount = 0, points > 0) quy ra VND.
        DB::table('campaign_donations')
            ->where('amount', 0)
            ->where('points', '>', 0)
            ->update([
                'amount' => DB::raw('points * ' . self::POINT_VALUE_VND),
            ]);

        // 2. Tính lại current_amount mỗi campaign = tổng amount của các lượt success.
        $totals = DB::table('campaign_donations')
            ->select('donation_campaign_id', DB::raw('SUM(amount) as total'))
            ->where('payment_status', 'success')
            ->groupBy('donation_campaign_id')
            ->pluck('total', 'donation_campaign_id');

        DB::table('donation_campaigns')->update(['current_amount' => 0]);
        foreach ($totals as $campaignId => $total) {
            DB::table('donation_campaigns')
                ->where('id', $campaignId)
                ->update(['current_amount' => $total]);
        }

        // 3. Bỏ các cột 2-trục không còn dùng.
        Schema::table('donation_campaigns', function (Blueprint $table) {
            $table->dropColumn(['type', 'target_points', 'current_points']);
        });
    }

    public function down(): void
    {
        Schema::table('donation_campaigns', function (Blueprint $table) {
            $table->enum('type', ['financial', 'points', 'both'])->default('both')->after('image_url');
            $table->integer('target_points')->default(0)->after('current_amount');
            $table->integer('current_points')->default(0)->after('target_points');
        });

        // Khôi phục current_points từ tổng points của các lượt success.
        $totals = DB::table('campaign_donations')
            ->select('donation_campaign_id', DB::raw('SUM(points) as total'))
            ->where('payment_status', 'success')
            ->groupBy('donation_campaign_id')
            ->pluck('total', 'donation_campaign_id');

        foreach ($totals as $campaignId => $total) {
            DB::table('donation_campaigns')
                ->where('id', $campaignId)
                ->update(['current_points' => $total]);
        }
    }
};
