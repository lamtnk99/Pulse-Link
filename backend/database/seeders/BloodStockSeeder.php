<?php

namespace Database\Seeders;

use App\Models\BloodDemandForecast;
use App\Models\BloodSafetyThreshold;
use App\Models\BloodStock;
use App\Models\DonationHistory;
use App\Models\Hospital;
use App\Models\SmartAlert;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class BloodStockSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $hospitals = Hospital::all();
        $bloodTypes = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

        foreach ($hospitals as $hospital) {
            // 1. Tạo ngưỡng an toàn mặc định (Safety Thresholds)
            foreach ($bloodTypes as $bloodType) {
                // Nhóm máu hiếm (Rh-) có ngưỡng an toàn thấp hơn (ví dụ 5-10 đơn vị)
                // Nhóm máu thường (Rh+) có ngưỡng cao hơn (ví dụ 20-30 đơn vị)
                $minUnits = str_ends_with($bloodType, '-') ? rand(5, 10) : rand(20, 30);

                BloodSafetyThreshold::updateOrCreate(
                    [
                        'hospital_id' => $hospital->id,
                        'blood_type' => $bloodType,
                    ],
                    [
                        'min_units' => $minUnits,
                    ]
                );
            }

            // 2. Tạo kho túi máu hiện tại (Blood Stocks)
            // Lấy một số lịch sử hiến máu để liên kết ngẫu nhiên
            $histories = DonationHistory::where('hospital_id', $hospital->id)
                ->where('status', 'verified')
                ->get();
            // Một lượt hiến chỉ có thể đại diện cho một đơn vị máu trong kho.
            // Khi thiếu lịch sử phù hợp, túi demo được để null thay vì tái sử dụng
            // donation_history_id và làm sai quan hệ nguồn gốc.
            $unusedHistoriesByType = $histories
                ->groupBy('blood_type')
                ->map(fn ($items) => $items->values());

            // Nhập ngẫu nhiên túi máu
            foreach ($bloodTypes as $bloodType) {
                // Lấy ngưỡng an toàn
                $threshold = BloodSafetyThreshold::where('hospital_id', $hospital->id)
                    ->where('blood_type', $bloodType)
                    ->first();

                // Xác định số lượng túi máu hiện tại
                // Để demo sinh cảnh báo khan hiếm, cho nhóm máu O- và B- dưới ngưỡng
                if (in_array($bloodType, ['O-', 'B-'])) {
                    $unitsCount = rand(1, 4); // Chắc chắn dưới ngưỡng (ngưỡng từ 5-10)
                } else {
                    $unitsCount = rand($threshold->min_units - 5, $threshold->min_units + 15);
                }

                for ($i = 0; $i < $unitsCount; $i++) {
                    $receivedDaysAgo = rand(1, 35);
                    $receivedDate = now()->subDays($receivedDaysAgo)->toDateString();
                    // Hạn sử dụng thường là 35 ngày kể từ ngày hiến
                    $expiryDate = Carbon::parse($receivedDate)->addDays(35)->toDateString();

                    // Xác định trạng thái ngẫu nhiên: hầu hết là available, một ít đã dùng, một ít hết hạn
                    $status = 'available';
                    if (Carbon::parse($expiryDate)->isPast()) {
                        $status = 'expired';
                    } elseif (rand(1, 10) <= 2) {
                        $status = 'used';
                    }

                    $matchingHistories = $unusedHistoriesByType->get($bloodType);
                    $history = $matchingHistories?->shift();

                    BloodStock::create([
                        'hospital_id' => $hospital->id,
                        'blood_type' => $bloodType,
                        'volume_ml' => rand(0, 1) === 0 ? 350 : 450,
                        'received_date' => $receivedDate,
                        'expiry_date' => $expiryDate,
                        'status' => $status,
                        'donation_history_id' => $history ? $history->id : null,
                        'notes' => $status === 'used' ? 'Đã sử dụng trong ca phẫu thuật.' : ($status === 'expired' ? 'Đã hủy do hết hạn bảo quản.' : 'Lưu kho thông thường.'),
                    ]);
                }
            }

            // 3. Tạo các cảnh báo thông minh (Smart Alerts)
            // Tạo 1-2 cảnh báo đang hoạt động (active) cho O- hoặc B-
            $scarceTypes = ['O-', 'B-'];
            foreach ($scarceTypes as $type) {
                $threshold = BloodSafetyThreshold::where('hospital_id', $hospital->id)
                    ->where('blood_type', $type)
                    ->first();
                $currentUnits = BloodStock::where('hospital_id', $hospital->id)
                    ->where('blood_type', $type)
                    ->where('status', 'available')
                    ->count();

                if ($currentUnits < $threshold->min_units) {
                    SmartAlert::create([
                        'hospital_id' => $hospital->id,
                        'blood_type' => $type,
                        'current_units' => $currentUnits,
                        'threshold_units' => $threshold->min_units,
                        'status' => 'active',
                        'triggered_at' => now()->subDays(rand(1, 3)),
                    ]);
                }
            }

            // Tạo một số cảnh báo trong quá khứ đã được giải quyết (resolved) hoặc đã huy động (mobilized)
            for ($j = 0; $j < 5; $j++) {
                $type = $bloodTypes[rand(0, count($bloodTypes) - 1)];
                $triggered = now()->subDays(rand(10, 30));
                $resolved = (clone $triggered)->addDays(rand(1, 4));

                SmartAlert::create([
                    'hospital_id' => $hospital->id,
                    'blood_type' => $type,
                    'current_units' => rand(1, 8),
                    'threshold_units' => rand(10, 20),
                    'status' => rand(0, 1) === 0 ? 'resolved' : 'mobilized',
                    'triggered_at' => $triggered,
                    'resolved_at' => $resolved,
                ]);
            }

            // 4. Tạo lịch sử dự báo AI nhu cầu máu (AI Forecasts)
            // Tạo dự báo cho 30 ngày qua (để hiển thị so sánh thực tế vs dự báo)
            // và 30 ngày tới (dự báo tương lai)
            $startDate = now()->subDays(15);
            $endDate = now()->addDays(15);

            for ($date = clone $startDate; $date->lte($endDate); $date->addDay()) {
                $targetDate = $date->toDateString();

                foreach ($bloodTypes as $bloodType) {
                    // Dự đoán thể tích nhu cầu trung bình hàng ngày dựa trên kích thước bệnh viện
                    // Ví dụ: Bạch Mai/Chợ Rẫy cần nhiều máu hơn
                    $baseDemand = str_contains($hospital->name, 'Bạch Mai') || str_contains($hospital->name, 'Chợ Rẫy') ? 1500 : 700;
                    
                    // Thêm biến động ngẫu nhiên
                    $randomFluctuation = rand(-200, 300);

                    // Thêm yếu tố mùa vụ (ví dụ: mùa hè/cuối tuần tăng nhẹ do tai nạn giao thông cấp cứu)
                    $seasonality = 0;
                    $dayOfWeek = $date->dayOfWeek;
                    if ($dayOfWeek === Carbon::SATURDAY || $dayOfWeek === Carbon::SUNDAY) {
                        $seasonality += 150; // Tăng cuối tuần
                    }
                    if (in_array($date->month, [6, 7, 8])) {
                        $seasonality += 200; // Mùa hè tăng do tai nạn/dịch sốt xuất huyết
                    }

                    $predictedVolume = max(350, $baseDemand + $randomFluctuation + $seasonality);

                    BloodDemandForecast::create([
                        'hospital_id' => $hospital->id,
                        'forecast_date' => now()->subDays(15)->toDateString(), // Dự báo được lập ra từ 15 ngày trước
                        'target_date' => $targetDate,
                        'blood_type' => $bloodType,
                        'predicted_volume_ml' => $predictedVolume,
                        'confidence_score' => rand(80, 95) / 100,
                        'explanation' => "Dựa trên xu hướng lịch sử sử dụng máu của nhóm {$bloodType} tại khu vực và phân tích yếu tố mùa vụ (tháng {$date->month}) cộng với tỷ lệ cấp cứu dịp cuối tuần.",
                    ]);
                }
            }
        }
    }
}
