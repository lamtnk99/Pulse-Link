<?php

namespace App\Domain\Emergency;

use App\Domain\Geo\DistanceCalculator;
use App\Domain\Geo\GeoPoint;
use App\Models\Hospital;
use App\Models\User;
use Illuminate\Support\Collection;

final class DispatchWavePolicy
{
    private const LOCAL_RADIUS_KM = 15;

    public function __construct(
        private readonly DistanceCalculator $distanceCalculator,
    ) {}

    /**
     * @param  Collection<int, User>  $donors
     * @return array{recipients: array<int, DispatchCandidate>, summary: array<string, mixed>}
     */
    public function selectRecipients(Collection $donors, Hospital $hospital, string $level): array
    {
        $hospitalPoint = new GeoPoint($hospital->latitude, $hospital->longitude);
        $recipients = [];
        $summary = [
            'local5km' => 0,
            'province30km' => 0,
            'inter_province' => 0,
            'rejected_out_of_range' => 0,
        ];

        foreach ($donors as $donor) {
            if ($donor->latitude === null || $donor->longitude === null) {
                continue;
            }

            $distance = $this->distanceCalculator->kilometers(
                new GeoPoint((float) $donor->latitude, (float) $donor->longitude),
                $hospitalPoint,
            );

            $wave = $this->waveFor($distance, $donor->province_code, $hospital->province_code, $level);

            if ($wave === null) {
                $summary['rejected_out_of_range']++;

                continue;
            }

            $summary[$wave]++;
            $recipients[] = new DispatchCandidate($donor, $wave, round($distance, 3));
        }

        usort($recipients, fn (DispatchCandidate $a, DispatchCandidate $b): int => $a->distanceKm <=> $b->distanceKm);

        return [
            'recipients' => $recipients,
            'summary' => $summary,
        ];
    }

    private function waveFor(float $distanceKm, ?string $donorProvince, string $hospitalProvince, string $level): ?string
    {
        if ($distanceKm <= self::LOCAL_RADIUS_KM) {
            return 'local5km';
        }

        if (in_array($level, ['level2', 'level3'], true)
            && $distanceKm <= 30
            && $donorProvince === $hospitalProvince) {
            return 'province30km';
        }

        if ($level === 'level3' && $distanceKm > 50 && $distanceKm <= 120) {
            return 'inter_province';
        }

        return null;
    }
}
