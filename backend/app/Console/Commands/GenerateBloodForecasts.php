<?php

namespace App\Console\Commands;

use App\Jobs\GenerateBloodForecast;
use App\Models\Hospital;
use App\Services\AI\InventoryForecastService;
use Illuminate\Console\Command;

class GenerateBloodForecasts extends Command
{
    protected $signature = 'blood-forecast:generate {--hospital_id=}';
    protected $description = 'Tạo dự báo tồn kho máu chính thức cho một hoặc toàn bộ bệnh viện đang hoạt động.';

    public function handle(InventoryForecastService $forecastService): int
    {
        $hospitals = Hospital::query()
            ->where('is_active', true)
            ->when($this->option('hospital_id'), fn ($query, $hospitalId) => $query->whereKey($hospitalId))
            ->get();

        foreach ($hospitals as $hospital) {
            $run = $forecastService->createRun($hospital, 'scheduled');
            GenerateBloodForecast::dispatch($run->id);
            $this->line("Đã xếp hàng dự báo cho {$hospital->name} (#{$run->id}).");
        }

        return self::SUCCESS;
    }
}
