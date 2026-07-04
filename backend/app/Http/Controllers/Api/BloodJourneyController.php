<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\BloodJourneyResource;
use App\Models\BloodJourney;
use Illuminate\Http\JsonResponse;
use Illuminate\View\View;

class BloodJourneyController extends Controller
{
    public function show(string $publicId): JsonResponse
    {
        return response()->json([
            'data' => BloodJourneyResource::make($this->findJourney($publicId))->resolve(),
        ]);
    }

    public function page(string $publicId): View
    {
        $journey = $this->findJourney($publicId);

        return view('journeys.show', [
            'journey' => BloodJourneyResource::make($journey)->resolve(),
        ]);
    }

    private function findJourney(string $publicId): BloodJourney
    {
        return BloodJourney::query()
            ->with('hospital', 'steps')
            ->where('public_id', $publicId)
            ->firstOrFail();
    }
}
