<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Domain\Geo\DistanceCalculator;
use App\Domain\Geo\GeoPoint;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RoutePlannerController extends Controller
{
    public function __construct(
        private readonly DistanceCalculator $distanceCalculator,
    ) {}

    public function plan(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'origin.latitude' => ['required', 'numeric', 'between:-90,90'],
            'origin.longitude' => ['required', 'numeric', 'between:-180,180'],
            'destination.latitude' => ['required', 'numeric', 'between:-90,90'],
            'destination.longitude' => ['required', 'numeric', 'between:-180,180'],
            'preferred_distance_km' => ['nullable', 'numeric', 'min:0'],
        ]);

        $origin = new GeoPoint(
            (float) $payload['origin']['latitude'],
            (float) $payload['origin']['longitude'],
        );
        $destination = new GeoPoint(
            (float) $payload['destination']['latitude'],
            (float) $payload['destination']['longitude'],
        );
        $distanceKm = round($this->distanceCalculator->kilometers($origin, $destination), 2);
        $estimatedMinutes = max(3, (int) ceil(($payload['preferred_distance_km'] ?? $distanceKm) / 24 * 60));

        $midpoint = [
            'latitude' => round(($origin->latitude + $destination->latitude) / 2, 7),
            'longitude' => round(($origin->longitude + $destination->longitude) / 2, 7),
        ];

        return response()->json([
            'data' => [
                'polyline' => [
                    ['latitude' => $origin->latitude, 'longitude' => $origin->longitude],
                    $midpoint,
                    ['latitude' => $destination->latitude, 'longitude' => $destination->longitude],
                ],
                'distance_km' => $distanceKm,
                'estimated_minutes' => $estimatedMinutes,
                'summary' => "Tuyen duong uu tien SOS khoang {$distanceKm} km",
            ],
        ]);
    }
}
