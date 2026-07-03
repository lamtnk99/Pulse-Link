<?php

namespace App\Services\Donations;

use App\Models\DonationHistory;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

class DonationRecognitionService
{
    public function prepareCertificateAttributes(array $attributes): array
    {
        $type = $attributes['donation_type'] ?? 'regular';

        return [
            ...$attributes,
            'donation_type' => $type,
            'certificate_title' => $attributes['certificate_title'] ?? $this->certificateTitle($type),
            'certificate_issued_at' => $attributes['certificate_issued_at'] ?? now(),
            'certificate_verify_token' => $attributes['certificate_verify_token'] ?? Str::upper(Str::random(16)),
        ];
    }

    public function refreshDonorRecognition(User $user): void
    {
        $histories = DonationHistory::query()
            ->where('user_id', $user->id)
            ->where('status', 'verified')
            ->get();

        $regularCount = $histories->where('donation_type', 'regular')->count()
            + $histories->where('donation_type', 'manual')->count();
        $sosCount = $histories->where('donation_type', 'sos')->count();
        $totalDonations = $histories->count();
        $points = $regularCount * 250 + $sosCount * 350;
        $lastDonationDate = $histories->max('donated_at');

        $user->update([
            'total_donations' => $totalDonations,
            'points' => $points,
            'last_donation_date' => $lastDonationDate,
            'hero_level' => $this->levelFor($totalDonations, $points),
            'badge_title' => $this->primaryBadgeTitle($totalDonations, $sosCount, (int) $histories->sum('volume_ml')),
        ]);
    }

    public function awardNewDonation(User $user, string $type, mixed $donatedAt = null): void
    {
        $points = $this->pointsFor($type);
        $donationDate = $donatedAt ? Carbon::parse($donatedAt)->toDateString() : now()->toDateString();
        $nextTotal = $user->total_donations + 1;
        $nextPoints = $user->points + $points;
        $totalVolumeMl = (int) DonationHistory::query()
            ->where('user_id', $user->id)
            ->where('status', 'verified')
            ->sum('volume_ml');
        $sosCount = DonationHistory::query()
            ->where('user_id', $user->id)
            ->where('status', 'verified')
            ->where('donation_type', 'sos')
            ->count();

        $user->update([
            'total_donations' => $nextTotal,
            'points' => $nextPoints,
            'last_donation_date' => $donationDate,
            'hero_level' => $this->levelFor($nextTotal, $nextPoints),
            'badge_title' => $this->primaryBadgeTitle($nextTotal, $sosCount, $totalVolumeMl),
        ]);
    }

    public function recognitionFor(User $user): array
    {
        $histories = DonationHistory::query()
            ->where('user_id', $user->id)
            ->where('status', 'verified')
            ->get();

        $totalVolumeMl = (int) $histories->sum('volume_ml');
        $sosCount = $histories->where('donation_type', 'sos')->count();
        $totalDonations = max((int) $user->total_donations, $histories->count());
        $points = (int) $user->points;

        return [
            'level' => $this->levelFor($totalDonations, $points),
            'badge_title' => $this->primaryBadgeTitle($totalDonations, $sosCount, $totalVolumeMl),
            'total_donations' => $totalDonations,
            'total_volume_ml' => $totalVolumeMl,
            'sos_donations' => $sosCount,
            'points' => $points,
            'global_rank' => $this->rankFor($user),
            'province_rank' => $this->rankFor($user, provinceScoped: true),
            'badges' => $this->badgesFor($totalDonations, $sosCount, $totalVolumeMl),
        ];
    }

    private function certificateTitle(string $type): string
    {
        return match ($type) {
            'sos' => 'Chứng nhận hiến máu khẩn cấp SOS',
            'manual' => 'Chứng nhận ghi nhận hiến máu',
            default => 'Chứng nhận hiến máu tình nguyện',
        };
    }

    private function pointsFor(string $type): int
    {
        return $type === 'sos' ? 350 : 250;
    }

    private function levelFor(int $donations, int $points): string
    {
        if ($donations >= 20 || $points >= 6000) {
            return 'Platinum Lifesaver';
        }
        if ($donations >= 10 || $points >= 3000) {
            return 'Gold Lifesaver';
        }
        if ($donations >= 5 || $points >= 1250) {
            return 'Silver Lifesaver';
        }

        return 'Bronze Lifesaver';
    }

    private function primaryBadgeTitle(int $donations, int $sosCount, int $totalVolumeMl): string
    {
        if ($sosCount >= 3) {
            return 'Người phản ứng SOS';
        }
        if ($donations >= 20) {
            return 'Người giữ sổ vàng';
        }
        if ($totalVolumeMl >= 3500) {
            return 'Dòng máu bền bỉ';
        }
        if ($donations >= 5) {
            return 'Người hiến đều đặn';
        }

        return 'Người hiến nhân ái';
    }

    private function badgesFor(int $donations, int $sosCount, int $totalVolumeMl): array
    {
        $badges = [];

        if ($donations >= 1) {
            $badges[] = $this->badge('first_donation', 'Lần hiến đầu', 'Đã có chứng nhận hiến máu đầu tiên.');
        }
        if ($donations >= 5) {
            $badges[] = $this->badge('five_donations', '5 lần hiến', 'Duy trì thói quen hiến máu an toàn.');
        }
        if ($donations >= 10) {
            $badges[] = $this->badge('ten_donations', '10 lần hiến', 'Cột mốc người hiến máu kỳ cựu.');
        }
        if ($sosCount >= 1) {
            $badges[] = $this->badge('sos_responder', 'SOS Responder', 'Đã hoàn thành một ca hiến máu khẩn cấp.');
        }
        if ($totalVolumeMl >= 2000) {
            $badges[] = $this->badge('two_liters', '2.000 ml sẻ chia', 'Tổng lượng máu hiến đã vượt 2.000 ml.');
        }

        return $badges;
    }

    private function badge(string $code, string $name, string $description): array
    {
        return compact('code', 'name', 'description');
    }

    private function rankFor(User $user, bool $provinceScoped = false): int
    {
        $query = User::query()
            ->where('role', 'donor')
            ->where('points', '>', $user->points);

        if ($provinceScoped && $user->province_code) {
            $query->where('province_code', $user->province_code);
        }

        return $query->count() + 1;
    }
}
