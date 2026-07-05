<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\CampaignDonation;
use App\Models\DonationHistory;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

/**
 * Số liệu tác động tập thể của cộng đồng Pulse Link, phục vụ cảm giác
 * "thuộc về" trên mobile: người dùng thấy mình là một phần của điều lớn hơn.
 */
class CommunityImpactController extends Controller
{
    public function index(): JsonResponse
    {
        $startOfMonth = now()->startOfMonth();

        $donationsThisMonth = DonationHistory::query()
            ->where('donated_at', '>=', $startOfMonth)
            ->count();

        $volumeThisMonth = (int) DonationHistory::query()
            ->where('donated_at', '>=', $startOfMonth)
            ->sum('volume_ml');

        // Số người hiến khác nhau trong tháng — hiệu ứng "cùng N người".
        $activeDonors = (int) DonationHistory::query()
            ->where('donated_at', '>=', $startOfMonth)
            ->distinct()
            ->count(DB::raw('COALESCE(user_id, id)'));

        // 1 đơn vị máu ~ giúp được 3 người bệnh (ước lượng phổ biến trong ngành).
        $livesTouched = $donationsThisMonth * 3;

        // Tường tri ân: những lời chúc gần đây từ cộng đồng quyên góp.
        $wall = CampaignDonation::query()
            ->where('payment_status', 'success')
            ->whereNotNull('message')
            ->where('message', '!=', '')
            ->latest('created_at')
            ->limit(12)
            ->get()
            ->map(fn (CampaignDonation $d): array => [
                'donor_name' => $d->is_anonymous ? 'Hiệp sĩ ẩn danh' : $d->donor_name,
                'message' => $d->message,
                'is_anonymous' => (bool) $d->is_anonymous,
                'created_at' => $d->created_at?->toIso8601String(),
            ])
            ->values();

        return response()->json([
            'data' => [
                'month_label' => 'Tháng '.now()->month.'/'.now()->year,
                'donations_this_month' => $donationsThisMonth,
                'volume_ml_this_month' => $volumeThisMonth,
                'active_donors' => $activeDonors,
                'lives_touched' => $livesTouched,
                'total_hero_count' => (int) User::query()->where('role', 'donor')->count(),
                'gratitude_wall' => $wall,
            ],
        ]);
    }
}
