<?php

namespace App\Services\AI;

use App\Models\BloodDemandForecast;
use App\Models\BloodForecastRun;
use App\Models\BloodSafetyThreshold;
use App\Models\BloodStock;
use App\Models\BloodStockMovement;
use App\Models\ForecastRecommendation;
use App\Models\Hospital;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Throwable;

/**
 * Numeric forecast engine for blood inventory. The model is deterministic:
 * GenAI can explain the result later but cannot replace these numbers.
 */
class InventoryForecastService
{
    public const MODEL_VERSION = 'inventory-ewma-weekday-v1';
    private const BLOOD_TYPES = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
    private const HISTORY_DAYS = 90;
    private const FORECAST_DAYS = 30;

    public function createRun(Hospital $hospital, string $trigger = 'manual', array $scenarios = [], ?int $generatedBy = null): BloodForecastRun
    {
        return BloodForecastRun::query()->create([
            'hospital_id' => $hospital->id,
            'status' => 'queued',
            'trigger' => $trigger,
            'model_version' => self::MODEL_VERSION,
            'generated_by' => $generatedBy,
            'scenarios' => $this->normalizedScenarios($scenarios),
        ]);
    }

    public function generate(BloodForecastRun $run): BloodForecastRun
    {
        $run->refresh();
        if ($run->status === 'completed') {
            return $run;
        }

        $run->update(['status' => 'running', 'error_message' => null]);

        try {
            $hospital = Hospital::query()->findOrFail($run->hospital_id);
            $today = now('Asia/Ho_Chi_Minh')->startOfDay();
            $start = $today->copy()->subDays(self::HISTORY_DAYS - 1);
            $movements = BloodStockMovement::query()
                ->where('hospital_id', $hospital->id)
                ->where('occurred_at', '>=', $start)
                ->where(function ($query): void {
                    $query->where('movement_type', 'sos_transfused')
                        ->orWhere(function ($used): void {
                            $used->where('movement_type', 'manual_status_updated')
                                ->where('to_status', 'used');
                        });
                })
                ->orderBy('occurred_at')
                ->get();

            $quality = $this->dataQuality($movements, $start, $today);
            $seriesByType = $this->dailyDemandSeries($movements, $start, $today);
            $collectionMovements = BloodStockMovement::query()
                ->where('hospital_id', $hospital->id)
                ->where('occurred_at', '>=', $start)
                ->where('available_delta', '>', 0)
                ->orderBy('occurred_at')
                ->get();
            $collectionSeriesByType = $this->dailyCollectionSeries($collectionMovements, $start, $today);
            $thresholds = BloodSafetyThreshold::query()
                ->where('hospital_id', $hospital->id)
                ->get()
                ->keyBy('blood_type');
            $availableByType = BloodStock::query()
                ->where('hospital_id', $hospital->id)
                ->where('status', 'available')
                ->selectRaw('blood_type, COUNT(*) as units')
                ->groupBy('blood_type')
                ->pluck('units', 'blood_type');

            $points = [];
            $metrics = [];
            $riskRows = [];

            foreach (self::BLOOD_TYPES as $bloodType) {
                $history = $seriesByType[$bloodType];
                $stat = $this->statistics($history);
                $confidence = $this->confidence($stat['wape'], $quality);
                $collectionStat = $this->statistics($collectionSeriesByType[$bloodType]);
                $projectedAvailable = (float) ($availableByType[$bloodType] ?? 0);
                $plannedIncoming = $this->incomingUnits($run->scenarios ?? [], $bloodType);
                $projectedAvailable += $plannedIncoming;
                $threshold = (float) ($thresholds[$bloodType]->min_units ?? 0);
                $shortageDate = null;

                for ($offset = 1; $offset <= self::FORECAST_DAYS; $offset++) {
                    $target = $today->copy()->addDays($offset);
                    $prediction = $this->predict($history, $target, $run->scenarios ?? []);
                    $lower = max(0, $prediction - (1.64 * $stat['mae']));
                    $upper = $prediction + (1.64 * $stat['mae']);
                    $expectedCollection = $this->predict($collectionSeriesByType[$bloodType], $target, [])
                        * (float) (($run->scenarios ?? [])['collection_multiplier'] ?? 1);
                    $projectedAvailable += $expectedCollection - $prediction;

                    if ($shortageDate === null && $projectedAvailable < $threshold) {
                        $shortageDate = $target->toDateString();
                    }

                    $points[] = [
                        'hospital_id' => $hospital->id,
                        'forecast_date' => $today->toDateString(),
                        'target_date' => $target->toDateString(),
                        'blood_type' => $bloodType,
                        'predicted_units' => round($prediction, 2),
                        'predicted_volume_ml' => (int) round($prediction * 350),
                        'lower_units' => round($lower, 2),
                        'upper_units' => round($upper, 2),
                        'confidence_score' => $confidence,
                        'model_version' => self::MODEL_VERSION,
                        'explanation' => $this->pointExplanation($bloodType, $prediction, $quality),
                    ];
                }

                $riskRows[] = [
                    'blood_type' => $bloodType,
                    'current_units' => (int) ($availableByType[$bloodType] ?? 0),
                    'threshold_units' => (int) $threshold,
                    'shortage_date' => $shortageDate,
                    'severity' => $this->severity($shortageDate, $today, (int) ($availableByType[$bloodType] ?? 0), (int) $threshold),
                    'projected_gap_units' => round(min(0, $projectedAvailable - $threshold) * -1, 2),
                    'planned_incoming_units' => $plannedIncoming,
                    'expected_collection_daily_units' => round($this->predict($collectionSeriesByType[$bloodType], $today->copy()->addDay(), []) * (float) (($run->scenarios ?? [])['collection_multiplier'] ?? 1), 2),
                ];
                $metrics[$bloodType] = [...$stat, 'collection_mae' => $collectionStat['mae']];
            }

            $recommendations = $this->recommendations($riskRows, $quality, $today);

            DB::transaction(function () use ($run, $points, $quality, $metrics, $riskRows, $recommendations, $today): void {
                BloodDemandForecast::query()->where('forecast_run_id', $run->id)->delete();
                foreach ($points as $point) {
                    BloodDemandForecast::query()->create([...$point, 'forecast_run_id' => $run->id]);
                }

                ForecastRecommendation::query()->where('forecast_run_id', $run->id)->delete();
                foreach ($recommendations as $recommendation) {
                    ForecastRecommendation::query()->create([
                        ...$recommendation,
                        'forecast_run_id' => $run->id,
                        'hospital_id' => $run->hospital_id,
                    ]);
                }

                $run->update([
                    'status' => 'completed',
                    'data_start_date' => $today->copy()->subDays(self::HISTORY_DAYS - 1)->toDateString(),
                    'data_end_date' => $today->toDateString(),
                    'generated_at' => now(),
                    'data_quality' => $quality,
                    'metrics' => ['by_blood_type' => $metrics, 'risk_rows' => $riskRows],
                    'reasoning_summary' => $this->summary($riskRows, $quality),
                    'recommendations' => $recommendations,
                    'ai_provider' => 'deterministic-template',
                ]);
            });
        } catch (Throwable $exception) {
            $run->update([
                'status' => 'failed',
                'error_message' => mb_substr($exception->getMessage(), 0, 4000),
            ]);
        }

        return $run->refresh();
    }

    private function dailyDemandSeries($movements, Carbon $start, Carbon $today): array
    {
        $byType = [];
        foreach (self::BLOOD_TYPES as $type) {
            $byType[$type] = [];
            for ($date = $start->copy(); $date->lte($today); $date->addDay()) {
                $byType[$type][$date->toDateString()] = 0.0;
            }
        }

        foreach ($movements as $movement) {
            $date = $movement->occurred_at->timezone('Asia/Ho_Chi_Minh')->toDateString();
            if (isset($byType[$movement->blood_type][$date])) {
                $byType[$movement->blood_type][$date] += (float) $movement->quantity_units;
            }
        }

        return $byType;
    }

    private function dailyCollectionSeries($movements, Carbon $start, Carbon $today): array
    {
        $byType = [];
        foreach (self::BLOOD_TYPES as $type) {
            $byType[$type] = [];
            for ($date = $start->copy(); $date->lte($today); $date->addDay()) {
                $byType[$type][$date->toDateString()] = 0.0;
            }
        }

        foreach ($movements as $movement) {
            $date = $movement->occurred_at->timezone('Asia/Ho_Chi_Minh')->toDateString();
            if (isset($byType[$movement->blood_type][$date])) {
                $byType[$movement->blood_type][$date] += (float) $movement->quantity_units;
            }
        }

        return $byType;
    }

    private function statistics(array $series): array
    {
        $values = array_values($series);
        $residuals = [];
        $absoluteActual = 0.0;
        $absoluteError = 0.0;
        $biasTotal = 0.0;

        for ($index = 7; $index < count($values); $index++) {
            $baseline = array_sum(array_slice($values, $index - 7, 7)) / 7;
            $error = $values[$index] - $baseline;
            $residuals[] = abs($error);
            $absoluteActual += abs($values[$index]);
            $absoluteError += abs($error);
            $biasTotal += $error;
        }

        $mae = count($residuals) ? array_sum($residuals) / count($residuals) : 1.0;

        return [
            'mae' => round($mae, 3),
            'wape' => $absoluteActual > 0 ? round($absoluteError / $absoluteActual, 3) : 1.0,
            'bias' => count($residuals) ? round($biasTotal / count($residuals), 3) : 0.0,
        ];
    }

    private function predict(array $series, Carbon $target, array $scenarios): float
    {
        $values = array_values($series);
        $recent = array_slice($values, -28);
        $rollingMean = count($recent) ? array_sum($recent) / count($recent) : 0.0;
        $ewma = $recent[0] ?? 0.0;
        foreach (array_slice($recent, 1) as $value) {
            $ewma = (0.3 * $value) + (0.7 * $ewma);
        }

        $sameWeekday = [];
        foreach ($series as $date => $value) {
            if (Carbon::parse($date)->dayOfWeek === $target->dayOfWeek) {
                $sameWeekday[] = $value;
            }
        }
        $weekdayMean = count($sameWeekday) ? array_sum($sameWeekday) / count($sameWeekday) : $rollingMean;
        $base = (0.5 * $ewma) + (0.3 * $weekdayMean) + (0.2 * $rollingMean);

        return max(0, $base * (float) ($scenarios['demand_multiplier'] ?? 1));
    }

    private function dataQuality($movements, Carbon $start, Carbon $today): array
    {
        $allDays = max(1, $start->diffInDays($today) + 1);
        $movementDays = $movements->map(fn (BloodStockMovement $movement) => $movement->occurred_at->toDateString())->unique()->count();
        $synthetic = $movements->where('is_synthetic', true)->count();
        $ratio = $movements->count() ? round($synthetic / $movements->count(), 3) : 1.0;
        $liveDays = $movements->where('is_synthetic', false)
            ->map(fn (BloodStockMovement $movement) => $movement->occurred_at->toDateString())
            ->unique()
            ->count();

        return [
            'level' => ($liveDays >= 56 && $ratio <= 0.5) ? 'high' : (($liveDays >= 28 && $ratio <= 0.5) ? 'medium' : 'low'),
            'data_days' => $allDays,
            'movement_days' => $movementDays,
            'live_days' => $liveDays,
            'synthetic_ratio' => $ratio,
            'is_demo' => $ratio > 0,
        ];
    }

    private function confidence(float $wape, array $quality): float
    {
        $factor = match ($quality['level']) {
            'high' => 1.0,
            'medium' => 0.75,
            default => 0.55,
        };
        $score = max(0.1, min(0.95, (1 - $wape) * $factor));

        return round($quality['level'] === 'low' ? min($score, 0.55) : $score, 2);
    }

    private function normalizedScenarios(array $scenarios): array
    {
        return [
            'demand_multiplier' => max(0.5, min(1.5, (float) ($scenarios['demand_multiplier'] ?? 1))),
            'collection_multiplier' => max(0.5, min(1.5, (float) ($scenarios['collection_multiplier'] ?? 1))),
            'incoming_units' => $scenarios['incoming_units'] ?? [],
        ];
    }

    private function incomingUnits(array $scenarios, string $bloodType): float
    {
        $incoming = $scenarios['incoming_units'] ?? [];
        if (! is_array($incoming)) {
            return 0.0;
        }

        return max(0, min(10000, (float) ($incoming[$bloodType] ?? 0)));
    }

    private function severity(?string $shortageDate, Carbon $today, int $currentUnits, int $threshold): string
    {
        if ($currentUnits < $threshold) {
            return 'critical';
        }
        if ($shortageDate === null) {
            return 'safe';
        }
        $days = $today->diffInDays(Carbon::parse($shortageDate));

        return $days <= 3 ? 'critical' : ($days <= 7 ? 'high' : 'medium');
    }

    private function recommendations(array $riskRows, array $quality, Carbon $today): array
    {
        $recommendations = [];
        foreach ($riskRows as $risk) {
            if ($risk['severity'] === 'safe') {
                continue;
            }
            $actionType = in_array($risk['severity'], ['critical', 'high'], true) ? 'create_event' : 'monitor';
            $recommendations[] = [
                'blood_type' => $risk['blood_type'],
                'action_type' => $actionType,
                'status' => 'suggested',
                'severity' => $risk['severity'],
                'title' => $actionType === 'create_event'
                    ? "Chuẩn bị đợt hiến bổ sung nhóm {$risk['blood_type']}"
                    : "Theo dõi sát tồn kho nhóm {$risk['blood_type']}",
                'rationale' => "Dự báo cho thấy tồn kho {$risk['blood_type']} có thể xuống dưới ngưỡng an toàn" . ($risk['shortage_date'] ? " vào {$risk['shortage_date']}" : '') . '.',
                'due_date' => $risk['shortage_date'] ?? $today->copy()->addDays(14)->toDateString(),
                'projected_gap_units' => $risk['projected_gap_units'],
                'payload' => ['data_quality' => $quality['level']],
            ];
        }

        return $recommendations;
    }

    private function summary(array $riskRows, array $quality): string
    {
        $risks = array_values(array_filter($riskRows, fn (array $row) => $row['severity'] !== 'safe'));
        if (count($risks) === 0) {
            return "Kho máu hiện chưa có nguy cơ thiếu trong 14 ngày tới. Độ tin cậy dữ liệu: {$quality['level']}.";
        }

        $types = implode(', ', array_column($risks, 'blood_type'));

        return "Cần ưu tiên theo dõi nhóm {$types}. Độ tin cậy dữ liệu: {$quality['level']}" . ($quality['is_demo'] ? ' (có dữ liệu mô phỏng).' : '.');
    }

    private function pointExplanation(string $bloodType, float $prediction, array $quality): string
    {
        return "Dự báo {$bloodType} dựa trên xu hướng xuất kho, nhịp theo ngày trong tuần và trung bình 28 ngày. Độ tin cậy dữ liệu: {$quality['level']}.";
    }
}
