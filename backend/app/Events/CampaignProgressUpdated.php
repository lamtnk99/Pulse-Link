<?php

namespace App\Events;

use App\Models\DonationCampaign;
use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CampaignProgressUpdated implements ShouldBroadcastNow
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(public DonationCampaign $campaign)
    {
    }

    public function broadcastOn(): array
    {
        return [
            new Channel('campaigns'),
            new Channel('campaign.'.$this->campaign->public_id),
        ];
    }

    public function broadcastAs(): string
    {
        return 'campaign.progress.updated';
    }

    public function broadcastWith(): array
    {
        $topDonors = $this->campaign->donations()
            ->where('payment_status', 'success')
            ->selectRaw('user_id, donor_name, is_anonymous, SUM(amount) as total_amount, SUM(points) as total_points, MAX(created_at) as last_donated_at')
            ->groupBy('user_id', 'donor_name', 'is_anonymous')
            ->orderByRaw('SUM(amount) DESC, SUM(points) DESC')
            ->limit(10)
            ->get()
            ->map(fn($d) => [
                'donor_name' => $d->is_anonymous ? 'Hiệp sĩ ẩn danh' : $d->donor_name,
                'amount' => (float) $d->total_amount,
                'points' => (int) $d->total_points,
                'last_donated_at' => $d->last_donated_at,
            ]);

        return [
            'campaign' => [
                'id' => $this->campaign->public_id,
                'title' => $this->campaign->title,
                'type' => $this->campaign->type,
                'target_amount' => (float) $this->campaign->target_amount,
                'current_amount' => (float) $this->campaign->current_amount,
                'target_points' => (int) $this->campaign->target_points,
                'current_points' => (int) $this->campaign->current_points,
                'status' => $this->campaign->status,
                'expires_at' => $this->campaign->expires_at?->toIso8601String(),
            ],
            'leaderboard' => $topDonors,
        ];
    }
}
