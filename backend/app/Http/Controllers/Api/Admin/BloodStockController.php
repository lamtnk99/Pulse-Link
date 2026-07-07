<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\BloodDemandForecast;
use App\Models\BloodSafetyThreshold;
use App\Models\BloodStock;
use App\Models\DonationEvent;
use App\Models\EmergencyAlert;
use App\Models\Hospital;
use App\Models\SmartAlert;
use App\Services\Admin\AdminUserResolver;
use App\Services\AI\BloodForecastService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class BloodStockController extends Controller
{
    public function __construct(
        private readonly AdminUserResolver $adminUserResolver,
        private readonly BloodForecastService $forecastService
    ) {}

    /**
     * Lấy danh sách tồn kho máu và các số liệu thống kê nhanh
     */
    public function index(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        
        $hospitalId = $request->integer('hospital_id');
        if ($admin->role !== 'system_admin') {
            $hospitalId = $admin->hospital_id;
        } elseif (!$hospitalId) {
            $hospitalId = Hospital::where('is_active', true)->value('id');
        }

        if (!$hospitalId) {
            return response()->json(['error' => 'Bệnh viện không tồn tại hoặc chưa chọn.'], 400);
        }

        // Tồn kho chi tiết (available)
        $stocks = BloodStock::where('hospital_id', $hospitalId)
            ->where('status', 'available')
            ->orderBy('expiry_date')
            ->get();

        // Ngưỡng an toàn để so sánh
        $thresholds = BloodSafetyThreshold::where('hospital_id', $hospitalId)->get()->keyBy('blood_type');

        // Phân rã theo nhóm máu
        $bloodTypes = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
        $breakdown = [];
        $scarcityAlertsCount = 0;

        foreach ($bloodTypes as $type) {
            $typeStocks = $stocks->where('blood_type', $type);
            $units = $typeStocks->count();
            $minUnits = $thresholds->has($type) ? $thresholds[$type]->min_units : 15;
            
            $isScarce = $units < $minUnits;
            if ($isScarce) {
                $scarcityAlertsCount++;
            }

            $breakdown[] = [
                'blood_type' => $type,
                'units' => $units,
                'min_units' => $minUnits,
                'volume_ml' => $typeStocks->sum('volume_ml'),
                'is_scarce' => $isScarce,
                'expiring_soon' => $typeStocks->filter(fn($item) => $item->expiry_date->isBefore(now()->addDays(7)) && !$item->expiry_date->isPast())->count(),
            ];
        }

        // Thống kê chung
        $stats = [
            'total_units' => $stocks->count(),
            'expiring_units' => BloodStock::where('hospital_id', $hospitalId)
                ->where('status', 'available')
                ->whereBetween('expiry_date', [now()->toDateString(), now()->addDays(7)->toDateString()])
                ->count(),
            'expired_units' => BloodStock::where('hospital_id', $hospitalId)
                ->where(fn($q) => $q->where('status', 'expired')->orWhere(fn($sq) => $sq->where('status', 'available')->where('expiry_date', '<', now()->toDateString())))
                ->count(),
            'scarcity_alerts_count' => $scarcityAlertsCount,
            'active_sos_requests' => EmergencyAlert::where('hospital_id', $hospitalId)->where('status', 'active')->count(),
        ];

        // Lấy tất cả danh sách túi máu để hiển thị bảng (hỗ trợ phân trang và bộ lọc)
        $query = BloodStock::where('hospital_id', $hospitalId)
            ->with('donationHistory.user')
            ->orderBy('id', 'desc');

        if ($request->filled('blood_type')) {
            $query->where('blood_type', $request->input('blood_type'));
        }

        if ($request->filled('status')) {
            $status = $request->input('status');
            if ($status === 'expiring_soon') {
                $query->where('status', 'available')
                    ->whereBetween('expiry_date', [now()->toDateString(), now()->addDays(7)->toDateString()]);
            } else {
                $query->where('status', $status);
            }
        }

        if ($request->filled('q')) {
            $search = $request->input('q');
            $query->where(function ($q) use ($search) {
                $q->where('notes', 'like', "%{$search}%")
                  ->orWhere('id', 'like', "%{$search}%")
                  ->orWhereHas('donationHistory.user', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        $allBags = $query->paginate($request->integer('per_page', 10));

        return response()->json([
            'data' => [
                'hospital_id' => $hospitalId,
                'stats' => $stats,
                'breakdown' => $breakdown,
                'bags' => $allBags,
            ]
        ]);
    }

    /**
     * Thêm túi máu mới vào kho
     */
    public function store(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        
        $hospitalId = $request->integer('hospital_id');
        if ($admin->role !== 'system_admin') {
            $hospitalId = $admin->hospital_id;
        }

        if (!$hospitalId) {
            return response()->json(['error' => 'Bệnh viện không hợp lệ.'], 403);
        }

        $request->validate([
            'blood_type' => 'required|in:O+,O-,A+,A-,B+,B-,AB+,AB-',
            'volume_ml' => 'required|integer|min:200|max:1000',
            'received_date' => 'required|date',
            'expiry_date' => 'required|date|after_or_equal:received_date',
            'notes' => 'nullable|string|max:255',
        ]);

        $stock = BloodStock::create([
            'hospital_id' => $hospitalId,
            'blood_type' => $request->input('blood_type'),
            'volume_ml' => $request->input('volume_ml'),
            'received_date' => $request->input('received_date'),
            'expiry_date' => $request->input('expiry_date'),
            'status' => 'available',
            'notes' => $request->input('notes'),
        ]);

        // Kiểm tra xem việc thêm túi máu có giải quyết được cảnh báo khan hiếm nào không
        $this->checkAndResolveAlert($hospitalId, $stock->blood_type);

        return response()->json([
            'message' => 'Thêm túi máu vào kho thành công.',
            'data' => $stock
        ], 201);
    }

    /**
     * Cập nhật trạng thái túi máu (Sử dụng/Hủy/Lưu kho)
     */
    public function updateStatus(Request $request, int $id): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        $stock = BloodStock::findOrFail($id);

        if ($admin->role !== 'system_admin' && (int)$admin->hospital_id !== (int)$stock->hospital_id) {
            abort(403, 'Bạn không có quyền quản lý kho máu của bệnh viện này.');
        }

        $request->validate([
            'status' => 'required|in:available,used,expired,allocated',
            'notes' => 'nullable|string|max:255',
        ]);

        $oldStatus = $stock->status;
        $stock->update([
            'status' => $request->input('status'),
            'notes' => $request->input('notes') ?? $stock->notes,
        ]);

        // Nếu chuyển trạng thái từ available sang trạng thái khác (ví dụ: đã dùng hoặc hết hạn)
        // Cần kiểm tra xem có kích hoạt cảnh báo khan hiếm mới không
        if ($oldStatus === 'available' && $stock->status !== 'available') {
            $this->checkAndTriggerAlert($stock->hospital_id, $stock->blood_type);
        }

        // Nếu chuyển ngược lại thành available
        if ($oldStatus !== 'available' && $stock->status === 'available') {
            $this->checkAndResolveAlert($stock->hospital_id, $stock->blood_type);
        }

        return response()->json([
            'message' => 'Cập nhật trạng thái túi máu thành công.',
            'data' => $stock
        ]);
    }

    /**
     * Lấy dự báo nhu cầu máu hoặc chạy dự báo mới từ AI
     */
    public function getForecast(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        
        $hospitalId = $request->integer('hospital_id');
        if ($admin->role !== 'system_admin') {
            $hospitalId = $admin->hospital_id;
        } elseif (!$hospitalId) {
            $hospitalId = Hospital::where('is_active', true)->value('id');
        }

        $hospital = Hospital::with('province')->findOrFail($hospitalId);

        // Kịch bản mô phỏng
        $scenarios = [
            'dengue_outbreak' => $request->boolean('dengue_outbreak', false),
            'holiday_season' => $request->boolean('holiday_season', false),
            'weather_extreme' => $request->boolean('weather_extreme', false),
        ];

        // Nếu gửi yêu cầu generate mới
        if ($request->isMethod('POST') || $request->boolean('force_refresh', false)) {
            $forecastResult = $this->forecastService->generateForecast($hospital, $scenarios);

            // Lưu kết quả dự báo mới vào DB
            DB::transaction(function () use ($hospitalId, $forecastResult) {
                // Xóa dự báo cũ của ngày hôm nay để tránh trùng lặp
                BloodDemandForecast::where('hospital_id', $hospitalId)
                    ->where('forecast_date', now()->toDateString())
                    ->delete();

                foreach ($forecastResult['forecast'] as $item) {
                    BloodDemandForecast::create([
                        'hospital_id' => $hospitalId,
                        'forecast_date' => now()->toDateString(),
                        'target_date' => now()->addDays(15)->toDateString(), // Dự đoán cho trung hạn
                        'blood_type' => $item['blood_type'],
                        'predicted_volume_ml' => $item['predicted_volume_ml'],
                        'confidence_score' => $item['confidence_score'],
                        'explanation' => $item['explanation'],
                    ]);
                }
            });

            $suggestedEvents = collect($forecastResult['suggested_events'] ?? [])->map(function ($event) use ($hospital) {
                $event['hospital_id'] = $hospital->id;
                if (($event['drive_type'] ?? '') === 'in_hospital') {
                    $event['location_name'] = $hospital->address;
                    $event['organizer'] = $hospital->name;
                    $event['province_code'] = $hospital->province_code;
                    $event['ward_code'] = $hospital->ward_code;
                    $event['latitude'] = $hospital->latitude;
                    $event['longitude'] = $hospital->longitude;
                } else {
                    $event['province_code'] ??= $hospital->province_code;
                    $event['ward_code'] ??= $hospital->ward_code;
                    $event['latitude'] ??= $hospital->latitude;
                    $event['longitude'] ??= $hospital->longitude;
                }
                return $event;
            })->all();

            return response()->json([
                'data' => [
                    'hospital_id' => $hospitalId,
                    'forecast_date' => now()->toDateString(),
                    'reasoning_summary' => $forecastResult['reasoning_summary'] ?? '',
                    'recommendations' => $forecastResult['recommendations'] ?? [],
                    'forecast' => $forecastResult['forecast'],
                    'suggested_events' => $suggestedEvents
                ]
            ]);
        }

        // Lấy dự báo gần nhất trong DB
        $forecasts = BloodDemandForecast::where('hospital_id', $hospitalId)
            ->where('forecast_date', '>=', now()->subDays(3)->toDateString())
            ->orderBy('forecast_date', 'desc')
            ->get();

        if ($forecasts->isEmpty()) {
            // Nếu chưa có, tự động sinh default mock/gemini forecast
            return $this->getForecast(new Request(['hospital_id' => $hospitalId, 'force_refresh' => true]));
        }

        $latestDate = $forecasts->first()->forecast_date->toDateString();
        $latestForecasts = $forecasts->where('forecast_date', $latestDate);

        // Định dạng dữ liệu trả về giống API sinh mới
        $explanationGroup = $latestForecasts->pluck('explanation')->filter()->first() ?? 'Dữ liệu dự báo AI cho các nhóm máu dựa trên các chỉ số hoạt động.';
        
        $forecastData = [];
        foreach ($latestForecasts as $f) {
            $forecastData[] = [
                'blood_type' => $f->blood_type,
                'predicted_volume_ml' => $f->predicted_volume_ml,
                'confidence_score' => $f->confidence_score,
                'explanation' => $f->explanation
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
                'urgency' => 'normal',
                'capacity' => 150,
                'hospital_id' => $hospital->id,
                'province_code' => $hospital->province_code,
                'ward_code' => $hospital->ward_code,
                'latitude' => $hospital->latitude,
                'longitude' => $hospital->longitude,
            ]
        ];

        return response()->json([
            'data' => [
                'hospital_id' => $hospitalId,
                'forecast_date' => $latestDate,
                'reasoning_summary' => $explanationGroup,
                'recommendations' => [
                    "Duy trì trữ lượng an toàn khuyến nghị cho các nhóm Rh-.",
                    "Lên kế hoạch đặt lịch hiến máu dựa trên biểu đồ nhu cầu.",
                ],
                'forecast' => $forecastData,
                'suggested_events' => $suggestedEvents
            ]
        ]);
    }

    /**
     * Quản lý ngưỡng an toàn tồn kho (Thresholds)
     */
    public function getThresholds(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        
        $hospitalId = $request->integer('hospital_id');
        if ($admin->role !== 'system_admin') {
            $hospitalId = $admin->hospital_id;
        } elseif (!$hospitalId) {
            $hospitalId = Hospital::where('is_active', true)->value('id');
        }

        $thresholds = BloodSafetyThreshold::where('hospital_id', $hospitalId)->get();

        return response()->json([
            'data' => $thresholds
        ]);
    }

    public function updateThresholds(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        
        $hospitalId = $request->integer('hospital_id');
        if ($admin->role !== 'system_admin') {
            $hospitalId = $admin->hospital_id;
        }

        if (!$hospitalId) {
            return response()->json(['error' => 'Bệnh viện không hợp lệ.'], 403);
        }

        $request->validate([
            'thresholds' => 'required|array',
            'thresholds.*.blood_type' => 'required|in:O+,O-,A+,A-,B+,B-,AB+,AB-',
            'thresholds.*.min_units' => 'required|integer|min:0|max:200',
        ]);

        $updated = [];
        foreach ($request->input('thresholds') as $t) {
            $record = BloodSafetyThreshold::updateOrCreate(
                [
                    'hospital_id' => $hospitalId,
                    'blood_type' => $t['blood_type'],
                ],
                [
                    'min_units' => $t['min_units'],
                ]
            );
            $updated[] = $record;

            // Kiểm tra lại trạng thái cảnh báo sau khi đổi ngưỡng
            $this->checkAndResolveAlert($hospitalId, $t['blood_type']);
            $this->checkAndTriggerAlert($hospitalId, $t['blood_type']);
        }

        return response()->json([
            'message' => 'Cập nhật ngưỡng an toàn thành công.',
            'data' => $updated
        ]);
    }

    /**
     * Lấy các cảnh báo thông minh (Smart Alerts)
     */
    public function getAlerts(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        
        $hospitalId = $request->integer('hospital_id');
        if ($admin->role !== 'system_admin') {
            $hospitalId = $admin->hospital_id;
        } elseif (!$hospitalId) {
            $hospitalId = Hospital::where('is_active', true)->value('id');
        }

        $alerts = SmartAlert::where('hospital_id', $hospitalId)
            ->orderBy('id', 'desc')
            ->limit(30)
            ->get();

        return response()->json([
            'data' => $alerts
        ]);
    }

    /**
     * Kích hoạt huy động khẩn cấp từ cảnh báo khan hiếm
     * Trả về template bài viết đã soạn sẵn để Admin duyệt và đẩy lên CMS
     */
    public function mobilizeAlert(Request $request, int $id): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        $alert = SmartAlert::findOrFail($id);

        if ($admin->role !== 'system_admin' && (int)$admin->hospital_id !== (int)$alert->hospital_id) {
            abort(403, 'Bạn không có quyền quản lý cảnh báo này.');
        }

        $alert->update(['status' => 'mobilized']);
        $hospital = Hospital::find($alert->hospital_id);

        // Tạo template bài viết khẩn cấp
        $bloodType = $alert->blood_type;
        $title = "🚨 KHẨN CẤP: Kêu gọi hiến máu nhóm {$bloodType} cứu người tại {$hospital->name}";
        $content = "Hệ thống Pulse-Link ghi nhận lượng máu dự trữ nhóm {$bloodType} tại kho máu của Bệnh viện {$hospital->name} đã rơi xuống mức báo động đỏ (chỉ còn {$alert->current_units} đơn vị so với ngưỡng an toàn {$alert->threshold_units} đơn vị).\n\n"
            . "Chúng tôi khẩn thiết kêu gọi các tình nguyện viên mang nhóm máu {$bloodType} (đặc biệt là các tình nguyện viên có vị trí lân cận khu vực bệnh viện) hãy thu xếp thời gian đến hiến máu cứu người giúp tháo gỡ khó khăn cho ngân hàng máu.\n\n"
            . "📍 Địa điểm tiếp nhận: {$hospital->address}\n"
            . "📞 Số điện thoại liên hệ: " . ($hospital->contact_phone ?? 'Phòng công tác xã hội bệnh viện') . "\n\n"
            . "Xin chân thành cảm ơn nghĩa cử cao đẹp của quý vị!";

        return response()->json([
            'message' => 'Đã kích hoạt kế hoạch huy động người hiến.',
            'data' => [
                'alert_id' => $alert->id,
                'target_blood_type' => $bloodType,
                'hospital_id' => $alert->hospital_id,
                'draft_post' => [
                    'title' => $title,
                    'content' => $content,
                    'target_audience' => "Chỉ nhắm mục tiêu Nhóm máu {$bloodType} (Khẩn cấp)",
                    'province_code' => $hospital->province_code,
                ]
            ]
        ]);
    }

    /**
     * Báo cáo và thống kê (Reports)
     */
    public function getReports(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        
        $hospitalId = $request->integer('hospital_id');
        if ($admin->role !== 'system_admin') {
            $hospitalId = $admin->hospital_id;
        } elseif (!$hospitalId) {
            $hospitalId = Hospital::where('is_active', true)->value('id');
        }

        // 1. Tỷ lệ sử dụng máu (Used vs Expired)
        $totalUsed = BloodStock::where('hospital_id', $hospitalId)->where('status', 'used')->count();
        $totalExpired = BloodStock::where('hospital_id', $hospitalId)->where('status', 'expired')->count();
        $totalAvailable = BloodStock::where('hospital_id', $hospitalId)->where('status', 'available')->count();
        $totalSum = $totalUsed + $totalExpired + $totalAvailable;

        $utilizationRate = $totalSum > 0 ? round(($totalUsed / $totalSum) * 100, 2) : 100.0;
        $wasteRate = $totalSum > 0 ? round(($totalExpired / $totalSum) * 100, 2) : 0.0;

        // 2. Hiệu quả các chiến dịch hiến máu (lượng ml thu thập trung bình trên mỗi sự kiện)
        $events = DonationEvent::where('hospital_id', $hospitalId)
            ->where('ends_at', '<', now())
            ->withCount('appointments')
            ->orderBy('ends_at', 'desc')
            ->limit(10)
            ->get();

        $campaignsEfficiency = [];
        foreach ($events as $event) {
            // Lấy lượng máu đã hiến thành công
            $volume = DB::table('donation_histories')
                ->where('hospital_id', $hospitalId)
                ->where('location_name', $event->location_name)
                ->sum('volume_ml');

            $campaignsEfficiency[] = [
                'event_title' => $event->title,
                'appointments_count' => $event->appointments_count,
                'volume_collected_ml' => (int) $volume,
                'efficiency_ratio' => $event->appointments_count > 0 ? round($volume / $event->appointments_count, 1) : 0
            ];
        }

        // 3. Hiệu suất điều phối SOS
        $sosAlerts = EmergencyAlert::where('hospital_id', $hospitalId)
            ->withCount(['commitments' => fn($q) => $q->where('status', '!=', 'cancelled')])
            ->withCount(['commitments as donated_count' => fn($q) => $q->where('status', 'donated')])
            ->orderBy('id', 'desc')
            ->limit(10)
            ->get();

        $sosPerformance = [];
        foreach ($sosAlerts as $alert) {
            $turnoutRate = $alert->commitments_count > 0 
                ? round(($alert->donated_count / $alert->commitments_count) * 100, 2) 
                : 0;

            $sosPerformance[] = [
                'alert_id' => $alert->public_id,
                'blood_type' => $alert->required_blood_type,
                'units_needed' => $alert->units_needed,
                'commitments_count' => $alert->commitments_count,
                'donated_count' => $alert->donated_count,
                'turnout_rate' => $turnoutRate,
                'status' => $alert->status
            ];
        }

        return response()->json([
            'data' => [
                'utilization' => [
                    'used_count' => $totalUsed,
                    'expired_count' => $totalExpired,
                    'available_count' => $totalAvailable,
                    'utilization_rate' => $utilizationRate,
                    'waste_rate' => $wasteRate,
                ],
                'campaigns_efficiency' => $campaignsEfficiency,
                'sos_performance' => $sosPerformance,
            ]
        ]);
    }

    // --- Hàm trợ giúp nội bộ ---

    private function checkAndTriggerAlert(int $hospitalId, string $bloodType): void
    {
        $threshold = BloodSafetyThreshold::where('hospital_id', $hospitalId)
            ->where('blood_type', $bloodType)
            ->first();

        if (!$threshold) return;

        $currentUnits = BloodStock::where('hospital_id', $hospitalId)
            ->where('blood_type', $bloodType)
            ->where('status', 'available')
            ->count();

        if ($currentUnits < $threshold->min_units) {
            // Kiểm tra xem đã có alert active nào chưa
            $exists = SmartAlert::where('hospital_id', $hospitalId)
                ->where('blood_type', $bloodType)
                ->where('status', 'active')
                ->exists();

            if (!$exists) {
                SmartAlert::create([
                    'hospital_id' => $hospitalId,
                    'blood_type' => $bloodType,
                    'current_units' => $currentUnits,
                    'threshold_units' => $threshold->min_units,
                    'status' => 'active',
                    'triggered_at' => now(),
                ]);
            }
        }
    }

    private function checkAndResolveAlert(int $hospitalId, string $bloodType): void
    {
        $threshold = BloodSafetyThreshold::where('hospital_id', $hospitalId)
            ->where('blood_type', $bloodType)
            ->first();

        if (!$threshold) return;

        $currentUnits = BloodStock::where('hospital_id', $hospitalId)
            ->where('blood_type', $bloodType)
            ->where('status', 'available')
            ->count();

        if ($currentUnits >= $threshold->min_units) {
            // Tự động đóng alert đang kích hoạt
            SmartAlert::where('hospital_id', $hospitalId)
                ->where('blood_type', $bloodType)
                ->where('status', 'active')
                ->update([
                    'status' => 'resolved',
                    'resolved_at' => now(),
                    'current_units' => $currentUnits,
                ]);
        }
    }
}
