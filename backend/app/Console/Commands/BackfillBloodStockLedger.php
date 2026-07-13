<?php

namespace App\Console\Commands;

use App\Models\BloodStock;
use App\Models\BloodStockMovement;
use Illuminate\Console\Command;

class BackfillBloodStockLedger extends Command
{
    protected $signature = 'blood-stock:backfill-ledger {--dry-run : Chỉ hiển thị số bản ghi sẽ được tạo}';
    protected $description = 'Tạo movement suy diễn cho các túi máu cũ chưa có ledger; các bản ghi này luôn được gắn synthetic.';

    public function handle(): int
    {
        $count = 0;
        $query = BloodStock::query()
            ->doesntHave('movements')
            ->orderBy('id');

        if ($this->option('dry-run')) {
            $this->info('Sẽ backfill '.$query->count().' túi máu chưa có movement.');

            return self::SUCCESS;
        }

        $query->chunkById(250, function ($stocks) use (&$count): void {
            foreach ($stocks as $stock) {
                $wasAvailableBeforeCurrentStatus = $stock->status !== 'processing';
                $receivedKey = "backfill:stock:{$stock->id}:received";
                BloodStockMovement::query()->firstOrCreate(
                    ['idempotency_key' => $receivedKey],
                    [
                        'hospital_id' => $stock->hospital_id,
                        'blood_stock_id' => $stock->id,
                        'donation_history_id' => $stock->donation_history_id,
                        'blood_type' => $stock->blood_type,
                        'movement_type' => 'backfill_received',
                        'to_status' => $wasAvailableBeforeCurrentStatus ? 'available' : 'processing',
                        'quantity_units' => 1,
                        'volume_ml' => $stock->volume_ml,
                        'available_delta' => $wasAvailableBeforeCurrentStatus ? 1 : 0,
                        'source_type' => 'backfill',
                        'source_id' => $stock->id,
                        'is_synthetic' => true,
                        'notes' => 'Suy diễn từ túi máu tồn tại trước khi có inventory ledger.',
                        'occurred_at' => $stock->received_date->startOfDay(),
                    ],
                );

                if (in_array($stock->status, ['used', 'expired', 'discarded', 'allocated'], true)) {
                    $movementType = $stock->status === 'used' ? 'manual_status_updated' : 'backfill_'.$stock->status;
                    BloodStockMovement::query()->firstOrCreate(
                        ['idempotency_key' => "backfill:stock:{$stock->id}:{$stock->status}"],
                        [
                            'hospital_id' => $stock->hospital_id,
                            'blood_stock_id' => $stock->id,
                            'donation_history_id' => $stock->donation_history_id,
                            'blood_type' => $stock->blood_type,
                            'movement_type' => $movementType,
                            'from_status' => 'available',
                            'to_status' => $stock->status,
                            'quantity_units' => 1,
                            'volume_ml' => $stock->volume_ml,
                            'available_delta' => -1,
                            'source_type' => 'backfill',
                            'source_id' => $stock->id,
                            'is_synthetic' => true,
                            'notes' => 'Trạng thái lịch sử suy diễn khi backfill ledger.',
                            'occurred_at' => $stock->updated_at,
                        ],
                    );
                }
                $count++;
            }
        });

        $this->info("Đã backfill {$count} túi máu. Dữ liệu được gắn synthetic và phải hiển thị độ tin cậy thấp.");

        return self::SUCCESS;
    }
}
