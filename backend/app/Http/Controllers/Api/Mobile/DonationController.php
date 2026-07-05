<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\DonationCampaign;
use App\Models\CampaignDonation;
use App\Events\CampaignProgressUpdated;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class DonationController extends Controller
{
    public function index(): JsonResponse
    {
        $campaigns = DonationCampaign::query()
            ->where('status', 'active')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(fn($c) => $this->formatCampaign($c));

        return response()->json(['data' => $campaigns]);
    }

    public function show($id): JsonResponse
    {
        $campaign = DonationCampaign::query()
            ->where('public_id', $id)
            ->firstOrFail();

        // Get Top Donors Leaderboard. We surface the most recent heartfelt message
        // per donor so the "Bảng vàng tri ân" reads as people, not just amounts.
        $leaderboard = $campaign->donations()
            ->where('payment_status', 'success')
            ->selectRaw('id, user_id, donor_name, is_anonymous, message, amount, points, created_at')
            ->orderByRaw('amount DESC, points DESC, created_at DESC')
            ->get()
            ->groupBy(fn($d) => $d->user_id ?? 'guest-' . $d->id)
            ->map(function ($group) {
                $first = $group->first();
                $latestWithMessage = $group
                    ->filter(fn($d) => filled($d->message))
                    ->sortByDesc('created_at')
                    ->first();

                return [
                    'donor_name' => $first->is_anonymous ? 'Hiệp sĩ ẩn danh' : $first->donor_name,
                    'amount' => (float) $group->sum('amount'),
                    'points' => (int) $group->sum('points'),
                    'message' => $latestWithMessage?->message,
                    'is_anonymous' => (bool) $first->is_anonymous,
                    'last_donated_at' => $group->max('created_at'),
                ];
            })
            ->sortByDesc(fn($d) => [$d['amount'], $d['points']])
            ->take(10)
            ->values();

        return response()->json([
            'data' => [
                'campaign' => $this->formatCampaign($campaign),
                'leaderboard' => $leaderboard,
            ]
        ]);
    }

    public function donateCash(Request $request, $id): JsonResponse
    {
        $campaign = DonationCampaign::query()
            ->where('public_id', $id)
            ->where('status', 'active')
            ->firstOrFail();

        if ($campaign->type === 'points') {
            return response()->json(['message' => 'Chiến dịch này chỉ chấp nhận quyên góp điểm Hero.'], 422);
        }

        $payload = $request->validate([
            'amount' => ['required', 'numeric', 'min:1000'],
            'payment_method' => ['required', 'string', 'in:momo,vnpay,bank_transfer'],
            'donor_name' => ['nullable', 'string', 'max:255'],
            'message' => ['nullable', 'string', 'max:500'],
            'is_anonymous' => ['nullable', 'boolean'],
        ]);

        $user = $request->user();
        $transactionId = 'TXN-' . strtoupper(Str::random(12));

        $donation = CampaignDonation::create([
            'donation_campaign_id' => $campaign->id,
            'user_id' => $user?->id,
            'amount' => $payload['amount'],
            'points' => 0,
            'payment_method' => $payload['payment_method'],
            'payment_status' => 'pending',
            'transaction_id' => $transactionId,
            'donor_name' => $payload['donor_name'] ?: ($user ? $user->name : 'Hiệp sĩ ẩn danh'),
            'message' => $payload['message'],
            'is_anonymous' => $payload['is_anonymous'] ?? false,
        ]);

        // Generate mock payment URL pointing to our mock gateway
        $paymentUrl = route('mock-payment.show', ['transaction_id' => $transactionId]);

        return response()->json([
            'data' => [
                'donation_id' => $donation->id,
                'transaction_id' => $transactionId,
                'payment_url' => $paymentUrl,
            ]
        ]);
    }

    public function donatePoints(Request $request, $id): JsonResponse
    {
        $campaign = DonationCampaign::query()
            ->where('public_id', $id)
            ->where('status', 'active')
            ->firstOrFail();

        if ($campaign->type === 'financial') {
            return response()->json(['message' => 'Chiến dịch này chỉ chấp nhận quyên góp tài chính.'], 422);
        }

        $payload = $request->validate([
            'points' => ['required', 'integer', 'min:1'],
            'donor_name' => ['nullable', 'string', 'max:255'],
            'message' => ['nullable', 'string', 'max:500'],
            'is_anonymous' => ['nullable', 'boolean'],
        ]);

        $user = $request->user();
        if (!$user) {
            return response()->json(['message' => 'Yêu cầu đăng nhập để quyên góp điểm.'], 401);
        }

        $points = (int) $payload['points'];

        if ($user->points < $points) {
            throw ValidationException::withMessages([
                'points' => ['Số dư điểm Hero không đủ để thực hiện quyên góp.'],
            ]);
        }

        $donation = DB::transaction(function () use ($campaign, $user, $points, $payload) {
            // Deduct user points
            $user->decrement('points', $points);

            // Create success donation
            $donation = CampaignDonation::create([
                'donation_campaign_id' => $campaign->id,
                'user_id' => $user->id,
                'amount' => 0,
                'points' => $points,
                'payment_method' => 'points',
                'payment_status' => 'success',
                'transaction_id' => 'PTS-' . strtoupper(Str::random(12)),
                'donor_name' => $payload['donor_name'] ?: $user->name,
                'message' => $payload['message'],
                'is_anonymous' => $payload['is_anonymous'] ?? false,
            ]);

            // Increment campaign points
            $campaign->increment('current_points', $points);

            return $donation;
        });

        // Broadcast progress updated
        event(new CampaignProgressUpdated($campaign->refresh()));

        return response()->json([
            'message' => 'Quyên góp điểm Hero Points thành công!',
            'data' => [
                'donation_id' => $donation->id,
                'remaining_points' => $user->fresh()->points,
            ]
        ]);
    }

    public function paymentWebhook(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'transaction_id' => ['required', 'string'],
            'status' => ['required', 'string', 'in:success,failed'],
        ]);

        $donation = CampaignDonation::query()
            ->where('transaction_id', $payload['transaction_id'])
            ->firstOrFail();

        if ($donation->payment_status !== 'pending') {
            return response()->json(['message' => 'Giao dịch đã được xử lý trước đó.'], 400);
        }

        DB::transaction(function () use ($donation, $payload) {
            if ($payload['status'] === 'success') {
                $donation->update(['payment_status' => 'success']);
                $donation->campaign->increment('current_amount', $donation->amount);
            } else {
                $donation->update(['payment_status' => 'failed']);
            }
        });

        // Broadcast updated campaign
        if ($payload['status'] === 'success') {
            event(new CampaignProgressUpdated($donation->campaign->refresh()));
        }

        return response()->json(['message' => 'Webhook xử lý thành công.']);
    }

    private function formatCampaign(DonationCampaign $campaign): array
    {
        // donor_count: số người thực sự đã đóng góp thành công (đếm theo người, không theo lượt),
        // dùng cho hiệu ứng cộng đồng "cùng N hiệp sĩ".
        $donorCount = $campaign->donations()
            ->where('payment_status', 'success')
            ->distinct()
            ->count(DB::raw('COALESCE(user_id, id)'));

        return [
            'id' => $campaign->public_id,
            'title' => $campaign->title,
            'description' => $campaign->description,
            'image_url' => $campaign->image_url,
            'type' => $campaign->type,
            'target_amount' => (float) $campaign->target_amount,
            'current_amount' => (float) $campaign->current_amount,
            'target_points' => (int) $campaign->target_points,
            'current_points' => (int) $campaign->current_points,
            'status' => $campaign->status,
            'beneficiary_name' => $campaign->beneficiary_name,
            'beneficiary_story' => $campaign->beneficiary_story,
            'impact_unit' => $campaign->impact_unit,
            'impact_per_unit_amount' => $campaign->impact_per_unit_amount !== null
                ? (float) $campaign->impact_per_unit_amount
                : null,
            'impact_per_unit_points' => $campaign->impact_per_unit_points !== null
                ? (int) $campaign->impact_per_unit_points
                : null,
            'urgency_level' => $campaign->urgency_level,
            'donor_count' => $donorCount,
            'expires_at' => $campaign->expires_at?->toIso8601String(),
            'created_at' => $campaign->created_at?->toIso8601String(),
        ];
    }
}
