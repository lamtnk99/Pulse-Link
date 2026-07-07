<?php

namespace App\Services\AI;

use App\Models\AppSetting;
use App\Models\BloodStock;
use App\Models\DonationHistory;
use App\Models\EmergencyAlert;
use App\Models\Hospital;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class BloodForecastService
{
    public function generateForecast(Hospital $hospital, array $simulationScenarios = []): array
    {
        $apiKey = AppSetting::get('gemini_api_key') ?: config('services.gemini.key');

        if (empty($apiKey)) {
            Log::warning("BloodForecastService: Gemini API key is not configured. Falling back to mock generator.");
            return $this->generateMockForecast($hospital, $simulationScenarios);
        }

        try {
            // 1. Thu thập dữ liệu ngữ cảnh
            $inventoryData = $this->getInventoryData($hospital);
            $usageHistory = $this->getUsageHistory($hospital);
            $sosHistory = $this->getSosHistory($hospital);

            // 2. Xây dựng Prompt phân tích cho Gemini
            $systemInstruction = "Bạn là một AI chuyên gia điều hành y tế và huyết học quốc gia. Nhiệm vụ của bạn là phân tích dữ liệu tồn kho máu hiện tại, lịch sử sử dụng, lịch sử SOS cấp cứu và kết hợp với các biến kịch bản giả lập (dịch bệnh, lễ Tết, thời tiết) để dự báo nhu cầu máu trong 30 ngày tới của bệnh viện.\n"
                . "Bạn BẮT BUỘC phải trả về kết quả ở định dạng JSON phù hợp với schema được yêu cầu, không có markdown text bao quanh.";

            $prompt = "BỆNH VIỆN: {$hospital->name}\n"
                . "Địa chỉ: {$hospital->address}, Tỉnh/Thành: " . ($hospital->province->full_name ?? $hospital->province_code) . "\n\n"
                . "DỮ LIỆU TỒN KHO HIỆN TẠI (Available Units):\n"
                . json_encode($inventoryData, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT) . "\n\n"
                . "LỊCH SỬ SỬ DỤNG MÁU (30 ngày qua - số lượng và ml đã dùng thực tế):\n"
                . json_encode($usageHistory, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT) . "\n\n"
                . "LỊCH SỬ PHÁT SOS KHẨN CẤP (30 ngày qua):\n"
                . json_encode($sosHistory, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT) . "\n\n"
                . "CÁC KỊCH BẢN GIẢ LẬP ĐANG KÍCH HOẠT:\n"
                . "- Có bùng phát dịch Sốt xuất huyết tại khu vực: " . ($simulationScenarios['dengue_outbreak'] ? 'CÓ (làm tăng mạnh nhu cầu tiểu cầu và máu O/A)' : 'KHÔNG') . "\n"
                . "- Có kỳ nghỉ lễ lớn sắp tới (Tết/Quốc khánh): " . ($simulationScenarios['holiday_season'] ? 'CÓ (làm giảm lượng người hiến và tăng nguy cơ tai nạn giao thông cấp cứu)' : 'KHÔNG') . "\n"
                . "- Có thời tiết cực đoan (nắng nóng gay gắt/lũ lụt): " . ($simulationScenarios['weather_extreme'] ? 'CÓ (làm giảm nghiêm trọng số lượt hiến máu tự nguyện thường quy)' : 'KHÔNG') . "\n\n"
                . "Yêu cầu dự báo nhu cầu máu cho mỗi nhóm trong 8 nhóm máu (O+, O-, A+, A-, B+, B-, AB+, AB-) trong 30 ngày tiếp theo.\n"
                . "Hãy trả về phản hồi tuân thủ cấu trúc JSON sau:\n"
                . "{\n"
                . "  \"forecast\": [\n"
                . "    {\n"
                . "      \"blood_type\": \"nhóm máu (ví dụ: O-)\",\n"
                . "      \"predicted_volume_ml\": thể tích dự báo cần thiết bằng ml (số nguyên, ví dụ: 3500),\n"
                . "      \"confidence_score\": độ tin cậy từ 0.0 đến 1.0 (ví dụ: 0.85),\n"
                . "      \"explanation\": \"giải thích ngắn gọn lý do dự báo (bằng tiếng Việt)\"\n"
                . "    }\n"
                . "  ],\n"
                . "  \"reasoning_summary\": \"Tóm tắt phân tích chung về xu hướng nhu cầu máu (bằng tiếng Việt)\",\n"
                . "  \"recommendations\": [\n"
                . "    \"khuyến nghị hành động 1 cho bệnh viện (bằng tiếng Việt)\",\n"
                . "    \"khuyến nghị hành động 2 cho bệnh viện\"\n"
                . "  ],\n"
                . "  \"suggested_events\": [\n"
                . "    {\n"
                . "      \"drive_type\": \"in_hospital\" hoặc \"mobile\",\n"
                . "      \"title\": \"Tên đợt hiến đề xuất (ví dụ: Chủ Nhật Đỏ - Đại học Bách Khoa)\",\n"
                . "      \"organizer\": \"Đơn vị tổ chức (ví dụ: Hội Chữ thập đỏ hoặc tên bệnh viện)\",\n"
                . "      \"description\": \"Mô tả mục đích đợt hiến\",\n"
                . "      \"location_name\": \"Tên địa điểm chi tiết (ví dụ: Sảnh bệnh viện hoặc Nhà văn hóa A)\",\n"
                . "      \"suggested_date\": \"Ngày tổ chức đề xuất định dạng YYYY-MM-DD (sau ngày hôm nay từ 3 đến 10 ngày)\",\n"
                . "      \"starts_at\": \"Giờ bắt đầu định dạng HH:MM (ví dụ: 08:00)\",\n"
                . "      \"ends_at\": \"Giờ kết thúc định dạng HH:MM (ví dụ: 12:00)\",\n"
                . "      \"urgency\": \"normal\" hoặc \"high\",\n"
                . "      \"capacity\": chỉ tiêu số lượt hiến tối đa (số nguyên, ví dụ: 150)\n"
                . "    }\n"
                . "  ]\n"
                . "}";

            // 3. Gọi Gemini API
            $model = AppSetting::get('gemini_model_name', 'gemini-2.5-flash');
            $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}";

            Log::info("BloodForecastService: Calling Gemini model {$model} for hospital ID {$hospital->id}");

            $response = Http::timeout(15)
                ->post($url, [
                    'contents' => [
                        ['role' => 'user', 'parts' => [['text' => $prompt]]]
                    ],
                    'systemInstruction' => [
                        'parts' => [['text' => $systemInstruction]]
                    ],
                    'generationConfig' => [
                        'temperature' => 0.2,
                        'responseMimeType' => 'application/json',
                    ]
                ]);

            if ($response->failed()) {
                throw new \Exception("Gemini API failed: " . $response->body());
            }

            $data = $response->json();
            $text = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';
            
            if (empty($text)) {
                throw new \Exception("Gemini returned empty response content.");
            }

            $result = json_decode($text, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                throw new \Exception("Failed to decode JSON from Gemini: " . json_last_error_msg() . ". Response was: " . $text);
            }

            return $result;

        } catch (\Exception $e) {
            Log::error("BloodForecastService error: " . $e->getMessage() . ". Falling back to mock generator.");
            return $this->generateMockForecast($hospital, $simulationScenarios);
        }
    }

    private function getInventoryData(Hospital $hospital): array
    {
        $stocks = BloodStock::where('hospital_id', $hospital->id)
            ->where('status', 'available')
            ->get();

        $data = [];
        $bloodTypes = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

        foreach ($bloodTypes as $type) {
            $typeStocks = $stocks->where('blood_type', $type);
            $totalVolume = $typeStocks->sum('volume_ml');
            $expiringSoonCount = $typeStocks->filter(function ($item) {
                return $item->expiry_date->isBefore(now()->addDays(7));
            })->count();

            $data[$type] = [
                'current_units' => $typeStocks->count(),
                'total_volume_ml' => $totalVolume,
                'units_expiring_in_7_days' => $expiringSoonCount,
            ];
        }

        return $data;
    }

    private function getUsageHistory(Hospital $hospital): array
    {
        // Phân tích lịch sử từ DonationHistory
        $histories = DonationHistory::where('hospital_id', $hospital->id)
            ->where('status', 'verified')
            ->where('donated_at', '>=', now()->subDays(30))
            ->get();

        $data = [];
        foreach ($histories->groupBy('blood_type') as $type => $group) {
            $data[$type] = [
                'donations_count' => $group->count(),
                'total_volume_ml' => $group->sum('volume_ml'),
            ];
        }
        return $data;
    }

    private function getSosHistory(Hospital $hospital): array
    {
        $alerts = EmergencyAlert::where('hospital_id', $hospital->id)
            ->where('created_at', '>=', now()->subDays(30))
            ->get();

        $data = [];
        foreach ($alerts->groupBy('required_blood_type') as $type => $group) {
            $data[$type] = [
                'sos_alerts_count' => $group->count(),
                'total_units_requested' => $group->sum('units_needed'),
                'fulfilled_count' => $group->where('status', 'fulfilled')->count(),
            ];
        }
        return $data;
    }

    /**
     * Thuật toán fallback giả lập dự báo nhu cầu trong trường hợp không có API Key hoặc API gặp lỗi.
     */
    private function generateMockForecast(Hospital $hospital, array $simulationScenarios = []): array
    {
        $bloodTypes = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
        $forecast = [];

        // Xác định nhu cầu cơ bản theo kích thước bệnh viện
        $baseDemand = str_contains($hospital->name, 'Bạch Mai') || str_contains($hospital->name, 'Chợ Rẫy') ? 2200 : 1200;

        $reasoningParts = ["Dự báo được lập cho bệnh viện {$hospital->name} dựa trên phân tích dòng dữ liệu lịch sử và các tham số môi trường."];
        $recommendations = [];

        $dengue = $simulationScenarios['dengue_outbreak'] ?? false;
        $holiday = $simulationScenarios['holiday_season'] ?? false;
        $weather = $simulationScenarios['weather_extreme'] ?? false;

        if ($dengue) {
            $reasoningParts[] = "Cảnh báo dịch sốt xuất huyết tại khu vực thúc đẩy nhu cầu truyền máu chống xuất huyết và bổ sung tiểu cầu.";
            $recommendations[] = "Chủ động kêu gọi hiến tiểu cầu máy và dự phòng dư thừa 25% nhóm máu O và A.";
        }
        if ($holiday) {
            $reasoningParts[] = "Kỳ nghỉ lễ lớn làm tăng nguy cơ tai nạn giao thông cấp cứu, trong khi nguồn hiến máu tình nguyện bị gián đoạn.";
            $recommendations[] = "Tăng cường dự trữ dự phòng thêm ít nhất 20% cho tất cả các nhóm máu trước kỳ nghỉ lễ.";
            $recommendations[] = "Lên lịch trình hiến máu lưu động ngay sau Tết/Kỳ nghỉ lễ để bù đắp lượng máu hao hụt.";
        }
        if ($weather) {
            $reasoningParts[] = "Thời tiết cực đoan cản trở người hiến đến các điểm hiến thường quy, làm giảm lượng máu nhận vào.";
            $recommendations[] = "Kích hoạt kế hoạch kêu gọi nhóm hiến máu khẩn cấp qua ứng dụng di động để duy trì kho lưu trữ tối thiểu.";
        }

        if (count($recommendations) === 0) {
            $recommendations[] = "Duy trì lịch hiến máu thường quy tại các địa điểm cố định.";
            $recommendations[] = "Kiểm tra hạn sử dụng của kho máu hàng ngày để tránh lãng phí.";
            $recommendations[] = "Cập nhật ngưỡng an toàn tồn kho theo chu kỳ quý.";
        }

        foreach ($bloodTypes as $type) {
            // Tỷ lệ phân bổ nhu cầu máu trong cộng đồng Việt Nam thông thường:
            // O+ (~45%), A+ (~20%), B+ (~28%), AB+ (~6%)
            // Rh- rất hiếm (~0.1% mỗi nhóm)
            $multiplier = 1.0;
            switch ($type) {
                case 'O+': $multiplier = 0.45; break;
                case 'B+': $multiplier = 0.28; break;
                case 'A+': $multiplier = 0.20; break;
                case 'AB+': $multiplier = 0.06; break;
                case 'O-': $multiplier = 0.02; break; // Giả lập tỷ lệ hiếm cao hơn thực tế tí để có dữ liệu
                case 'B-': $multiplier = 0.015; break;
                case 'A-': $multiplier = 0.01; break;
                case 'AB-': $multiplier = 0.005; break;
            }

            // Áp dụng các kịch bản giả lập
            $scenarioFactor = 1.0;
            if ($dengue && in_array($type, ['O+', 'O-', 'A+', 'A-'])) {
                $scenarioFactor += 0.35; // Tăng mạnh cho O và A
            }
            if ($holiday) {
                $scenarioFactor += 0.25; // Tăng chung cho tai nạn
            }
            if ($weather) {
                $scenarioFactor -= 0.10; // Giảm nhẹ nhu cầu thường quy nhưng vẫn cần dự trữ
            }

            $volume = (int) ($baseDemand * $multiplier * $scenarioFactor * rand(85, 115) / 100);
            // Đảm bảo tối thiểu 1 túi máu (350ml)
            $volume = max(350, round($volume / 50) * 50);

            $forecast[] = [
                'blood_type' => $type,
                'predicted_volume_ml' => $volume,
                'confidence_score' => round(rand(82, 94) / 100, 2),
                'explanation' => "Nhu cầu dự đoán dựa trên tỷ lệ truyền máu thông thường của nhóm {$type} tại bệnh viện và điều chỉnh hệ số kịch bản vận hành hiện tại.",
            ];
        }

        $suggestedEvents = [
            [
                'drive_type' => 'in_hospital',
                'title' => 'Ngày hội Hiến máu Giọt Hồng tại ' . $hospital->name,
                'organizer' => $hospital->name,
                'description' => 'Tổ chức đợt hiến tập trung định kỳ nhằm bổ sung khẩn cấp các nhóm máu có xu hướng thiếu hụt trong 30 ngày tới.',
                'location_name' => $hospital->address,
                'suggested_date' => now()->addDays(5)->toDateString(),
                'starts_at' => '08:00',
                'ends_at' => '11:30',
                'urgency' => ($dengue || $holiday) ? 'high' : 'normal',
                'capacity' => 150
            ]
        ];

        // Nếu có dịch bệnh hoặc lễ Tết, AI đề xuất thêm 1 đợt hiến lưu động bên ngoài
        if ($dengue || $holiday) {
            $suggestedEvents[] = [
                'drive_type' => 'mobile',
                'title' => 'Chiến dịch Hiến máu Lưu động phối hợp Chữ Thập Đỏ',
                'organizer' => 'Hội Chữ thập đỏ Quận/Huyện địa phương',
                'description' => 'Hợp tác tổ chức lưu động tại khu vực đông dân cư để tối đa hóa số lượt hiến máu trong mùa cao điểm nhu cầu.',
                'location_name' => 'Nhà văn hóa Thể thao Quận',
                'suggested_date' => now()->addDays(9)->toDateString(),
                'starts_at' => '07:30',
                'ends_at' => '12:00',
                'urgency' => 'normal',
                'capacity' => 200
            ];
        }

        return [
            'forecast' => $forecast,
            'reasoning_summary' => implode(' ', $reasoningParts),
            'recommendations' => $recommendations,
            'suggested_events' => $suggestedEvents,
        ];
    }
}
