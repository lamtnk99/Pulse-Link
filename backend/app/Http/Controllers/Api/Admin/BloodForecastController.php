<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Jobs\GenerateBloodForecast;
use App\Models\BloodDemandForecast;
use App\Models\BloodForecastRun;
use App\Models\CommunityPost;
use App\Models\DonationEvent;
use App\Models\ForecastRecommendation;
use App\Models\Hospital;
use App\Services\Admin\AdminUserResolver;
use App\Services\AI\InventoryForecastService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class BloodForecastController extends Controller
{
    public function __construct(
        private readonly AdminUserResolver $adminUserResolver,
        private readonly InventoryForecastService $forecastService,
    ) {}

    public function overview(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'dashboard.view'), 403);
        $hospital = $this->resolveHospital($request, $admin->role, $admin->hospital_id);
        $horizon = $request->integer('horizon', 7);
        abort_unless(in_array($horizon, [7, 14, 30], true), 422);

        $run = BloodForecastRun::query()
            ->where('hospital_id', $hospital->id)
            ->where('status', 'completed')
            ->where('trigger', '!=', 'simulation')
            ->latest('generated_at')
            ->first();

        if (! $run) {
            return response()->json(['data' => null]);
        }

        $points = BloodDemandForecast::query()
            ->where('forecast_run_id', $run->id)
            ->orderBy('blood_type')
            ->orderBy('target_date')
            ->get();
        $cutoff = now('Asia/Ho_Chi_Minh')->startOfDay()->addDays($horizon)->toDateString();
        $horizonTotals = $points->where('target_date', '<=', $cutoff)
            ->groupBy('blood_type')
            ->map(fn ($items) => [
                'predicted_units' => round($items->sum('predicted_units'), 2),
                'lower_units' => round($items->sum('lower_units'), 2),
                'upper_units' => round($items->sum('upper_units'), 2),
                'confidence_score' => $items->avg('confidence_score'),
            ]);

        return response()->json([
            'data' => [
                'run' => $run,
                'horizon' => $horizon,
                'points' => $points,
                'horizon_totals' => $horizonTotals,
                'risk_rows' => $run->metrics['risk_rows'] ?? [],
                'recommendations' => ForecastRecommendation::query()
                    ->where('forecast_run_id', $run->id)
                    ->orderByRaw("CASE severity WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 ELSE 4 END")
                    ->get(),
            ],
        ]);
    }

    public function index(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'dashboard.view'), 403);
        $hospital = $this->resolveHospital($request, $admin->role, $admin->hospital_id);

        return response()->json([
            'data' => BloodForecastRun::query()
                ->where('hospital_id', $hospital->id)
                ->latest('created_at')
                ->paginate(min(max($request->integer('per_page', 15), 1), 50)),
        ]);
    }

    public function show(Request $request, BloodForecastRun $run): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $run->hospital_id), 403);

        return response()->json([
            'data' => [
                'run' => $run,
                'points' => $run->points()->orderBy('blood_type')->orderBy('target_date')->get(),
                'recommendations' => $run->recommendationRecords()->get(),
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'dashboard.view'), 403);
        $hospital = $this->resolveHospital($request, $admin->role, $admin->hospital_id);
        $existing = BloodForecastRun::query()
            ->where('hospital_id', $hospital->id)
            ->whereIn('status', ['queued', 'running'])
            ->where('trigger', '!=', 'simulation')
            ->latest('id')
            ->first();

        if ($existing) {
            return response()->json(['data' => $existing], 202);
        }

        $run = $this->forecastService->createRun($hospital, 'manual', [], $admin->id);
        GenerateBloodForecast::dispatch($run->id);

        return response()->json(['data' => $run], 202);
    }

    public function simulate(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'dashboard.view'), 403);
        $hospital = $this->resolveHospital($request, $admin->role, $admin->hospital_id);
        $payload = $request->validate([
            'demand_multiplier' => ['nullable', 'numeric', 'min:0.5', 'max:1.5'],
            'collection_multiplier' => ['nullable', 'numeric', 'min:0.5', 'max:1.5'],
            'incoming_units' => ['nullable', 'array'],
        ]);
        $run = $this->forecastService->createRun($hospital, 'simulation', $payload, $admin->id);
        GenerateBloodForecast::dispatch($run->id);

        return response()->json(['data' => $run], 202);
    }

    public function updateRecommendation(Request $request, ForecastRecommendation $recommendation): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $recommendation->hospital_id), 403);
        $payload = $request->validate([
            'status' => ['required', 'in:approved,dismissed,completed'],
            'resolution_note' => ['nullable', 'string', 'max:1000'],
        ]);
        $recommendation->update([
            ...$payload,
            'approved_by' => $payload['status'] === 'approved' ? $admin->id : $recommendation->approved_by,
            'approved_at' => $payload['status'] === 'approved' ? now() : $recommendation->approved_at,
        ]);

        return response()->json(['data' => $recommendation->refresh()]);
    }

    public function createDraftEvent(Request $request, ForecastRecommendation $recommendation): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'events.manage'), 403);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $recommendation->hospital_id), 403);
        abort_unless($recommendation->action_type === 'create_event', 422, 'Khuyến nghị này không tạo đợt hiến máu.');

        $validated = $request->validate([
            'recommendation_ids' => ['sometimes', 'array', 'min:1', 'max:8'],
            'recommendation_ids.*' => ['integer', 'distinct'],
        ]);
        $recommendationIds = collect($validated['recommendation_ids'] ?? [])
            ->push($recommendation->id)
            ->unique()
            ->values();
        $campaignRecommendations = ForecastRecommendation::query()
            ->whereIn('id', $recommendationIds)
            ->get();

        abort_unless($campaignRecommendations->count() === $recommendationIds->count(), 422, 'Có khuyến nghị không tồn tại.');
        abort_unless($campaignRecommendations->every(fn (ForecastRecommendation $item) => $item->hospital_id === $recommendation->hospital_id
            && $item->forecast_run_id === $recommendation->forecast_run_id
            && $item->action_type === 'create_event'
        ), 422, 'Chỉ có thể gom khuyến nghị cùng một forecast run và bệnh viện.');

        $existingDraftId = $campaignRecommendations
            ->map(fn (ForecastRecommendation $item) => ($item->payload ?? [])['draft_event_id'] ?? null)
            ->filter()
            ->first();
        if ($existingDraftId && ($existing = DonationEvent::query()->find($existingDraftId))) {
            return response()->json(['data' => $existing]);
        }

        $hospital = Hospital::query()->findOrFail($recommendation->hospital_id);
        // A few legacy hospital records predate the location master data. Only
        // persist a location target when its referenced master record exists.
        $provinceCode = $hospital->province?->code;
        $wardCode = $hospital->ward?->code;
        $earliestDueDate = $campaignRecommendations
            ->filter(fn (ForecastRecommendation $item) => $item->due_date !== null)
            ->sortBy(fn (ForecastRecommendation $item) => $item->due_date->timestamp)
            ->first()?->due_date;
        $startsAt = ($earliestDueDate?->copy() ?? now()->addDays(5))->setTime(8, 0);
        $bloodTypes = $campaignRecommendations->pluck('blood_type')->filter()->unique()->values()->implode(', ');
        $severityLabels = [
            'critical' => 'khẩn cấp',
            'high' => 'ưu tiên cao',
            'medium' => 'theo dõi',
        ];
        $needDetails = $campaignRecommendations->map(function (ForecastRecommendation $item) use ($severityLabels): string {
            $gap = max(0, (int) ceil((float) $item->projected_gap_units));
            $gapText = $gap > 0 ? "thiếu dự kiến {$gap} đơn vị" : 'có nguy cơ xuống dưới ngưỡng an toàn';
            $dueText = $item->due_date ? ' trước '.$item->due_date->format('d/m/Y') : '';
            $severity = $severityLabels[$item->severity] ?? $item->severity;

            return "- Nhóm {$item->blood_type}: {$gapText}{$dueText} · {$severity}.";
        })->implode("\n");
        $description = "Mục tiêu chiến dịch: tổ chức một đợt hiến máu để bổ sung đồng thời các nhóm {$bloodTypes}.\n\n"
            ."Chi tiết nhu cầu theo dự báo:\n{$needDetails}\n\n"
            .'Quy mô vận hành đề xuất: 120 lượt đăng ký. Nhân viên y tế kiểm tra lại nhu cầu thực tế trước khi công bố.';

        $event = DB::transaction(function () use ($hospital, $provinceCode, $wardCode, $startsAt, $bloodTypes, $description, $campaignRecommendations): DonationEvent {
            $event = DonationEvent::query()->create([
                'hospital_id' => $hospital->id,
                'drive_type' => 'in_hospital',
                'title' => 'Dự thảo · Chiến dịch hiến máu ưu tiên '.$bloodTypes,
                'organizer' => $hospital->name,
                'description' => $description,
                'starts_at' => $startsAt,
                'ends_at' => $startsAt->copy()->addHours(4),
                'location_name' => $hospital->address,
                'province_code' => $provinceCode,
                'ward_code' => $wardCode,
                'latitude' => $hospital->latitude,
                'longitude' => $hospital->longitude,
                'urgency' => $campaignRecommendations->contains(fn (ForecastRecommendation $item) => in_array($item->severity, ['critical', 'high'], true)) ? 'high' : 'normal',
                'capacity' => 120,
                'is_published' => false,
            ]);

            foreach ($campaignRecommendations as $item) {
                $item->update([
                    'status' => 'draft_created',
                    'payload' => [...($item->payload ?? []), 'draft_event_id' => $event->id],
                ]);
            }

            return $event;
        });

        return response()->json(['data' => $event], 201);
    }

    public function createDraftPost(Request $request, ForecastRecommendation $recommendation): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'posts.manage'), 403);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $recommendation->hospital_id), 403);

        $recommendationPayload = $recommendation->payload ?? [];
        $existingDraftId = $recommendationPayload['draft_post_id'] ?? null;
        if ($existingDraftId && ($existing = CommunityPost::query()->find($existingDraftId))) {
            return response()->json(['data' => $existing]);
        }

        $hospital = Hospital::query()->findOrFail($recommendation->hospital_id);
        $provinceCode = $hospital->province?->code;
        $wardCode = $hospital->ward?->code;
        $title = 'Dự thảo kêu gọi hiến máu nhóm '.($recommendation->blood_type ?? 'ưu tiên');
        $post = CommunityPost::query()->create([
            'hospital_id' => $hospital->id,
            'author_id' => $admin->id,
            'title' => $title,
            'slug' => Str::slug($title).'-'.Str::lower(Str::random(6)),
            'excerpt' => $recommendation->rationale,
            'content' => "Kính gửi cộng đồng người hiến máu,\n\n{$recommendation->rationale}\n\nĐây là bản nháp do hệ thống đề xuất. Bệnh viện sẽ công bố sau khi nhân viên y tế kiểm tra nhu cầu thực tế.",
            'status' => 'draft',
            'audience_type' => $recommendation->blood_type ? 'blood_type' : 'all',
            'target_blood_type' => $recommendation->blood_type,
            'province_code' => $provinceCode,
            'ward_code' => $wardCode,
        ]);
        $recommendation->update([
            'status' => 'draft_created',
            'payload' => [...$recommendationPayload, 'draft_post_id' => $post->id],
        ]);

        return response()->json(['data' => $post], 201);
    }

    private function resolveHospital(Request $request, string $role, ?int $scopedHospitalId): Hospital
    {
        $hospitalId = $role === 'system_admin'
            ? ($request->integer('hospital_id') ?: Hospital::query()->where('is_active', true)->value('id'))
            : $scopedHospitalId;

        return Hospital::query()->findOrFail($hospitalId);
    }
}
