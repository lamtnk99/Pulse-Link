<?php

namespace App\Repositories\Eloquent;

use App\Models\Province;
use App\Models\ProvinceAlias;
use App\Models\Ward;
use App\Repositories\Contracts\LocationRepository;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class EloquentLocationRepository implements LocationRepository
{
    public function activeProvinces(): Collection
    {
        return Province::query()
            ->where('is_active', true)
            ->orderBy('code')
            ->get();
    }

    public function wardsForProvince(string $provinceCode): Collection
    {
        return Ward::query()
            ->where('province_code', $provinceCode)
            ->where('is_active', true)
            ->orderBy('full_name')
            ->get();
    }

    public function normalizeProvince(string $value): ?Province
    {
        $normalized = $this->normalize($value);

        $province = Province::query()
            ->where('code', $value)
            ->orWhere('code_name', $normalized)
            ->orWhereRaw('lower(name_en) = ?', [strtolower($value)])
            ->first();

        if ($province instanceof Province) {
            return $province;
        }

        $alias = ProvinceAlias::query()
            ->with('province')
            ->where('normalized_alias', $normalized)
            ->first();

        return $alias?->province;
    }

    private function normalize(string $value): string
    {
        return Str::of($value)
            ->ascii()
            ->lower()
            ->replaceMatches('/[^a-z0-9]+/', '_')
            ->trim('_')
            ->toString();
    }
}
