<?php

namespace App\Services\AI;

use App\Models\Hospital;

/**
 * Compatibility adapter for the original blood-stocks/forecast endpoints.
 * Numeric values come from InventoryForecastService; this class deliberately
 * contains no model-generated or random fallback.
 */
class BloodForecastService
{
    public function __construct(private readonly InventoryForecastService $inventoryForecastService) {}

    public function generateForecast(Hospital $hospital, array $simulationScenarios = []): array
    {
        $demandMultiplier = 1.0;
        if (($simulationScenarios['dengue_outbreak'] ?? false) === true) {
            $demandMultiplier += 0.25;
        }
        if (($simulationScenarios['holiday_season'] ?? false) === true) {
            $demandMultiplier += 0.15;
        }

        $run = $this->inventoryForecastService->createRun($hospital, 'legacy', [
            'demand_multiplier' => $demandMultiplier,
            'collection_multiplier' => ($simulationScenarios['weather_extreme'] ?? false) ? 0.8 : 1.0,
        ]);
        $run = $this->inventoryForecastService->generate($run);
        $points = $run->points()->orderBy('blood_type')->orderBy('target_date')->get();

        $forecast = $points->groupBy('blood_type')->map(function ($items, string $bloodType): array {
            return [
                'blood_type' => $bloodType,
                'predicted_volume_ml' => (int) $items->sum('predicted_volume_ml'),
                'confidence_score' => round((float) $items->avg('confidence_score'), 2),
                'explanation' => (string) $items->first()->explanation,
            ];
        })->values()->all();

        $recommendations = $run->recommendationRecords()->get();

        return [
            'forecast' => $forecast,
            'reasoning_summary' => $run->reasoning_summary,
            'recommendations' => $recommendations->pluck('rationale')->values()->all(),
            'suggested_events' => $recommendations
                ->where('action_type', 'create_event')
                ->map(fn ($recommendation) => $this->suggestedEvent($hospital, $recommendation->blood_type, $recommendation->severity))
                ->values()
                ->all(),
        ];
    }

    private function suggestedEvent(Hospital $hospital, ?string $bloodType, string $severity): array
    {
        return [
            'drive_type' => 'in_hospital',
            'title' => 'Đợt hiến bổ sung nhóm '.$bloodType.' tại '.$hospital->name,
            'organizer' => $hospital->name,
            'description' => 'Bản nháp được đề xuất từ dự báo tồn kho. Nhân viên y tế cần kiểm tra và phê duyệt trước khi công bố.',
            'location_name' => $hospital->address,
            'suggested_date' => now()->addDays($severity === 'critical' ? 2 : 5)->toDateString(),
            'starts_at' => '08:00',
            'ends_at' => '11:30',
            'urgency' => in_array($severity, ['critical', 'high'], true) ? 'high' : 'normal',
            'capacity' => 120,
        ];
    }
}
