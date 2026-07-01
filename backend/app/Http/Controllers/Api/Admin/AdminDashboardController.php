<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\EmergencyAlertResource;
use App\Http\Resources\EmergencyCommitmentResource;
use App\Models\Hospital;
use App\Services\Emergency\EmergencyDispatchService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminDashboardController extends Controller
{
    public function __construct(
        private readonly EmergencyDispatchService $dispatchService,
    ) {}

    public function show(Request $request): JsonResponse
    {
        $hospitalId = $request->integer('hospital_id') ?: null;
        $payload = $this->dispatchService->activeDashboardPayload($hospitalId);

        return response()->json([
            'data' => [
                'hospitals' => Hospital::query()
                    ->with('province', 'ward')
                    ->where('is_active', true)
                    ->orderBy('name')
                    ->get(),
                'stats' => $payload['stats'],
                'alerts' => EmergencyAlertResource::collection($payload['alerts']),
                'commitments' => EmergencyCommitmentResource::collection($payload['commitments']),
            ],
        ]);
    }
}
