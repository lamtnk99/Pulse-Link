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

        // Số người hiến máu và quyên góp khác nhau trong tháng — hiệu ứng "cùng N người".
        $bloodDonorUserIds = DonationHistory::query()
            ->where('donated_at', '>=', $startOfMonth)
            ->whereNotNull('user_id')
            ->distinct()
            ->pluck('user_id')
            ->toArray();

        $campaignDonorUserIds = CampaignDonation::query()
            ->where('payment_status', 'success')
            ->where('created_at', '>=', $startOfMonth)
            ->whereNotNull('user_id')
            ->distinct()
            ->pluck('user_id')
            ->toArray();

        $uniqueUserIds = array_unique(array_merge($bloodDonorUserIds, $campaignDonorUserIds));
        $registeredCount = count($uniqueUserIds);

        $guestBloodCount = DonationHistory::query()
            ->where('donated_at', '>=', $startOfMonth)
            ->whereNull('user_id')
            ->count();

        $guestCampaignCount = CampaignDonation::query()
            ->where('payment_status', 'success')
            ->where('created_at', '>=', $startOfMonth)
            ->whereNull('user_id')
            ->distinct('donor_name')
            ->count('donor_name');

        $activeDonors = $registeredCount + $guestBloodCount + $guestCampaignCount;

        // Số lượt quyên góp chiến dịch trong tháng
        $campaignDonationsCount = CampaignDonation::query()
            ->where('payment_status', 'success')
            ->where('created_at', '>=', $startOfMonth)
            ->count();

        // Tổng số tiền quyên góp trong tháng (quy đổi 1 điểm = 5,000 VND)
        $cashAmountThisMonth = CampaignDonation::query()
            ->where('payment_status', 'success')
            ->where('created_at', '>=', $startOfMonth)
            ->sum('amount');

        $pointsThisMonth = CampaignDonation::query()
            ->where('payment_status', 'success')
            ->where('created_at', '>=', $startOfMonth)
            ->sum('points');

        $totalDonatedAmount = $cashAmountThisMonth + ($pointsThisMonth * 250);

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
                'campaign_donations_count' => $campaignDonationsCount,
                'total_donated_amount' => $totalDonatedAmount,
                'total_hero_count' => (int) User::query()->where('role', 'donor')->count(),
                'gratitude_wall' => $wall,
            ],
        ]);
    }
}
