<?php

namespace App\Repositories\Contracts;

use App\Models\Province;
use Illuminate\Support\Collection;

interface LocationRepository
{
    public function activeProvinces(): Collection;

    public function wardsForProvince(string $provinceCode): Collection;

    public function normalizeProvince(string $value): ?Province;
}
