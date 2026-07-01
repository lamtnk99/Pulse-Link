<?php

namespace App\Domain\Geo;

final readonly class GeoPoint
{
    public function __construct(
        public float $latitude,
        public float $longitude,
    ) {}
}
