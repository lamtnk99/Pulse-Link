<?php

namespace App\Domain\Emergency;

use App\Models\User;

final readonly class DispatchCandidate
{
    public function __construct(
        public User $donor,
        public string $wave,
        public float $distanceKm,
    ) {}
}
