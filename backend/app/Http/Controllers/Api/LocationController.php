<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProvinceResource;
use App\Http\Resources\WardResource;
use App\Models\Province;
use App\Repositories\Contracts\LocationRepository;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LocationController extends Controller
{
    public function __construct(
        private readonly LocationRepository $locations,
    ) {}

    public function provinces()
    {
        return ProvinceResource::collection($this->locations->activeProvinces());
    }

    public function wards(Province $province)
    {
        return WardResource::collection($this->locations->wardsForProvince($province->code));
    }

    public function normalize(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'value' => ['required', 'string', 'max:255'],
        ]);

        $province = $this->locations->normalizeProvince($payload['value']);

        return response()->json([
            'data' => [
                'matched' => $province !== null,
                'province' => $province ? ProvinceResource::make($province) : null,
            ],
        ]);
    }
}
