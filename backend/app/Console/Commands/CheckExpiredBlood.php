<?php

namespace App\Console\Commands;

use App\Models\BloodStock;
use App\Services\Inventory\BloodInventoryService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CheckExpiredBlood extends Command
{
    public function __construct(private readonly BloodInventoryService $bloodInventoryService)
    {
        parent::__construct();
    }
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'blood-stock:check-expiry';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Quét cơ sở dữ liệu để tự động chuyển trạng thái các túi máu quá hạn sử dụng sang EXPIRED và kích hoạt cảnh báo thông minh.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $today = now()->toDateString();
        
        $expiredBags = BloodStock::where('status', 'available')
            ->where('expiry_date', '<', $today)
            ->get();

        if ($expiredBags->isEmpty()) {
            $this->info('Không có túi máu nào hết hạn sử dụng hôm nay.');
            return 0;
        }

        $count = $expiredBags->count();
        $this->info("Phát hiện {$count} túi máu hết hạn. Đang tiến hành xử lý...");

        DB::transaction(function () use ($expiredBags) {
            foreach ($expiredBags as $bag) {
                $this->bloodInventoryService->transition(
                    stock: $bag,
                    toStatus: BloodInventoryService::STATUS_EXPIRED,
                    movementType: 'stock_expired',
                    sourceType: 'expiry_scan',
                    sourceId: $bag->id,
                    notes: 'Tự động hủy do quá hạn sử dụng (Hệ thống quét tự động).',
                    idempotencySuffix: 'available:expired:expiry-scan',
                );
            }
        });

        $this->info("Đã cập nhật trạng thái hết hạn cho {$count} túi máu thành công.");
        Log::info("CheckExpiredBlood: Đã tự động cập nhật hết hạn cho {$count} túi máu.");
        
        return 0;
    }
}
