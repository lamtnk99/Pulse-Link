<?php

namespace App\Console\Commands;

use App\Models\BloodSafetyThreshold;
use App\Models\BloodStock;
use App\Models\SmartAlert;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CheckExpiredBlood extends Command
{
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

        // Lưu thông tin để kiểm tra cảnh báo khan hiếm sau khi cập nhật
        $affectedHospitals = [];

        DB::transaction(function () use ($expiredBags, &$affectedHospitals) {
            foreach ($expiredBags as $bag) {
                $bag->update([
                    'status' => 'expired',
                    'notes' => 'Tự động hủy do quá hạn sử dụng (Hệ thống quét tự động).'
                ]);

                $key = $bag->hospital_id . '-' . $bag->blood_type;
                $affectedHospitals[$key] = [
                    'hospital_id' => $bag->hospital_id,
                    'blood_type' => $bag->blood_type
                ];
            }
        });

        // Quét các bệnh viện bị ảnh hưởng để kích hoạt Smart Alerts nếu cần
        foreach ($affectedHospitals as $info) {
            $hospitalId = $info['hospital_id'];
            $bloodType = $info['blood_type'];

            $threshold = BloodSafetyThreshold::where('hospital_id', $hospitalId)
                ->where('blood_type', $bloodType)
                ->first();

            if (!$threshold) continue;

            $currentUnits = BloodStock::where('hospital_id', $hospitalId)
                ->where('blood_type', $bloodType)
                ->where('status', 'available')
                ->count();

            if ($currentUnits < $threshold->min_units) {
                $alertExists = SmartAlert::where('hospital_id', $hospitalId)
                    ->where('blood_type', $bloodType)
                    ->where('status', 'active')
                    ->exists();

                if (!$alertExists) {
                    SmartAlert::create([
                        'hospital_id' => $hospitalId,
                        'blood_type' => $bloodType,
                        'current_units' => $currentUnits,
                        'threshold_units' => $threshold->min_units,
                        'status' => 'active',
                        'triggered_at' => now(),
                    ]);
                    
                    Log::warning("CheckExpiredBlood: Đã kích hoạt cảnh báo khan hiếm tự động cho nhóm {$bloodType} tại bệnh viện ID {$hospitalId} do hao hụt quá hạn.");
                }
            }
        }

        $this->info("Đã cập nhật trạng thái hết hạn cho {$count} túi máu thành công.");
        Log::info("CheckExpiredBlood: Đã tự động cập nhật hết hạn cho {$count} túi máu.");
        
        return 0;
    }
}
