<?php

namespace App\Jobs;

use App\Models\BloodForecastRun;
use App\Services\AI\InventoryForecastService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class GenerateBloodForecast implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public readonly int $forecastRunId) {}

    public function handle(InventoryForecastService $forecastService): void
    {
        $run = BloodForecastRun::query()->find($this->forecastRunId);
        if ($run) {
            $forecastService->generate($run);
        }
    }
}
