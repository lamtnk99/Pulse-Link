<?php

namespace App\Http\Controllers\Api\Admin;

use App\Events\EmergencyCommitmentUpdated;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreEmergencyAlertRequest;
use App\Http\Resources\EmergencyAlertResource;
use App\Models\EmergencyAlert;
use App\Models\EmergencyCommitment;
use App\Models\Hospital;
use App\Services\Emergency\EmergencyDispatchService;
use App\Services\Mobile\MobileUserResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Throwable;

class EmergencyController extends Controller
{
    public function __construct(
        private readonly EmergencyDispatchService $dispatchService,
        private readonly MobileUserResolver $mobileUserResolver,
    ) {}

    public function store(StoreEmergencyAlertRequest $request)
    {
        $hospital = Hospital::query()->findOrFail($request->integer('hospital_id'));
        $alert = $this->dispatchService->activate($hospital, $request->validated());

        return EmergencyAlertResource::make($alert)
            ->response()
            ->setStatusCode(201);
    }

    public function show(EmergencyAlert $alert): EmergencyAlertResource
    {
        return EmergencyAlertResource::make(
            $alert->load('hospital.province', 'hospital.ward', 'recipients.donor.province', 'commitments.donor.province')
        );
    }

    public function cancel(EmergencyAlert $alert): EmergencyAlertResource
    {
        $alert->update(['status' => 'cancelled']);

        return EmergencyAlertResource::make($alert->refresh()->load('hospital'));
    }

    public function commit(Request $request, EmergencyAlert $alert): JsonResponse
    {
        $payload = $request->validate([
            'donor_id' => ['nullable', 'integer', 'exists:users,id'],
            'latitude' => ['nullable', 'numeric'],
            'longitude' => ['nullable', 'numeric'],
            'eta_minutes' => ['nullable', 'integer', 'min:1', 'max:240'],
        ]);
        $donor = $this->mobileUserResolver->resolve(
            $payload['donor_id'] ?? $request->integer('user_id')
        );

        $commitment = EmergencyCommitment::query()->updateOrCreate(
            [
                'emergency_alert_id' => $alert->id,
                'donor_id' => $donor->id,
            ],
            [
                'status' => 'committed',
                'latitude' => $payload['latitude'] ?? null,
                'longitude' => $payload['longitude'] ?? null,
                'eta_minutes' => $payload['eta_minutes'] ?? null,
                'committed_at' => now(),
                'last_location_at' => now(),
            ],
        );

        $this->broadcastCommitment($commitment);

        return response()->json([
            'data' => [
                'id' => $commitment->id,
                'status' => $commitment->status,
            ],
        ]);
    }

    public function updateLocation(Request $request, EmergencyAlert $alert): JsonResponse
    {
        $payload = $request->validate([
            'donor_id' => ['nullable', 'integer', 'exists:users,id'],
            'latitude' => ['required', 'numeric'],
            'longitude' => ['required', 'numeric'],
            'eta_minutes' => ['nullable', 'integer', 'min:1', 'max:240'],
            'status' => ['nullable', 'in:committed,en_route,arrived,cancelled'],
        ]);
        $donor = $this->mobileUserResolver->resolve(
            $payload['donor_id'] ?? $request->integer('user_id')
        );

        $commitment = EmergencyCommitment::query()
            ->where('emergency_alert_id', $alert->id)
            ->where('donor_id', $donor->id)
            ->firstOrFail();

        $commitment->update([
            'latitude' => $payload['latitude'],
            'longitude' => $payload['longitude'],
            'eta_minutes' => $payload['eta_minutes'] ?? $commitment->eta_minutes,
            'status' => $payload['status'] ?? $commitment->status,
            'last_location_at' => now(),
        ]);

        $this->broadcastCommitment($commitment);

        return response()->json(['data' => ['ok' => true]]);
    }

    private function broadcastCommitment(EmergencyCommitment $commitment): void
    {
        try {
            broadcast(new EmergencyCommitmentUpdated($commitment));
        } catch (Throwable $exception) {
            Log::warning('Emergency commitment broadcast skipped.', [
                'commitment_id' => $commitment->id,
                'message' => $exception->getMessage(),
            ]);
        }
    }
}
