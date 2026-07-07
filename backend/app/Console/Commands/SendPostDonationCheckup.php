<?php

namespace App\Console\Commands;

use App\Models\DonationHistory;
use App\Services\Donations\PostDonationCareService;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class SendPostDonationCheckup extends Command
{
    protected $signature = 'app:send-post-donation-checkup';

    protected $description = 'Gửi tin nhắn hỏi thăm sức khỏe tự động sau 24h-48h kể từ ca hiến máu';

    public function __construct(
        private readonly PostDonationCareService $postDonationCareService,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $this->info('Bắt đầu quét danh sách hiến máu để gửi tin hỏi thăm...');

        $startDate = Carbon::today()->subDays(2)->startOfDay();
        $endDate = Carbon::today()->subDays(1)->endOfDay();

        $donations = DonationHistory::query()
            ->with(['user', 'hospital'])
            ->whereBetween('donated_at', [$startDate, $endDate])
            ->where('status', 'verified')
            ->get();

        $this->info('Tìm thấy '.$donations->count().' lượt hiến máu trong khoảng 24h-48h qua.');

        $sentCount = 0;

        foreach ($donations as $donation) {
            if ($this->postDonationCareService->createForDonation($donation)) {
                $sentCount++;
            }
        }

        $this->info("Đã gửi thành công {$sentCount} tin nhắn hỏi thăm sức khỏe.");

        return Command::SUCCESS;
    }
}
