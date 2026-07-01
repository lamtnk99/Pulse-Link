<?php

namespace App\Domain\Geo;

final class DistanceCalculator
{
    public function kilometers(GeoPoint $from, GeoPoint $to): float
    {
        $earthRadiusKm = 6371.0;
        $dLat = deg2rad($to->latitude - $from->latitude);
        $dLon = deg2rad($to->longitude - $from->longitude);
        $lat1 = deg2rad($from->latitude);
        $lat2 = deg2rad($to->latitude);

        $a = sin($dLat / 2) ** 2
            + cos($lat1) * cos($lat2) * sin($dLon / 2) ** 2;

        return $earthRadiusKm * (2 * atan2(sqrt($a), sqrt(1 - $a)));
    }
}
