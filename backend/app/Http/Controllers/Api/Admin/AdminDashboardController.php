<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\AdminUserResource;
use App\Http\Resources\EmergencyAlertResource;
use App\Http\Resources\EmergencyCommitmentResource;
use App\Models\DonationAppointment;
use App\Models\DonationEvent;
use App\Models\DonationHistory;
use App\Models\Hospital;
use App\Services\Admin\AdminUserResolver;
use App\Services\Emergency\EmergencyDispatchService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminDashboardController extends Controller
{
    public function __construct(
        private readonly EmergencyDispatchService $dispatchService,
        private readonly AdminUserResolver $adminUserResolver,
    ) {}

    public function show(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        $hospitalId = $request->integer('hospital_id') ?: null;
        if ($admin->role !== 'system_admin') {
            $hospitalId = $admin->hospital_id;
        }
        $payload = $this->dispatchService->activeDashboardPayload($hospitalId);
        $eventsQuery = DonationEvent::query()
            ->when($hospitalId, fn ($query) => $query->where('hospital_id', $hospitalId));
        $appointmentQuery = DonationAppointment::query()
            ->whereHas('event', fn ($query) => $query->when($hospitalId, fn ($query) => $query->where('hospital_id', $hospitalId)));
        $historyQuery = DonationHistory::query()
            ->when($hospitalId, fn ($query) => $query->where('hospital_id', $hospitalId));

        return response()->json([
            'data' => [
                'hospitals' => Hospital::query()
                    ->with('province', 'ward')
                    ->where('is_active', true)
                    ->when($admin->role !== 'system_admin', fn ($query) => $query->whereKey($admin->hospital_id))
                    ->orderBy('name')
                    ->get(),
                'stats' => [
                    ...$payload['stats'],
                    'upcoming_events' => (clone $eventsQuery)
                        ->where('is_published', true)
                        ->where('starts_at', '>=', now())
                        ->count(),
                    'scheduled_appointments' => (clone $appointmentQuery)
                        ->whereIn('status', ['booked', 'checked_in'])
                        ->count(),
                    'completed_appointments' => (clone $appointmentQuery)
                        ->where('status', 'completed')
                        ->count(),
                    'verified_volume_ml' => (int) (clone $historyQuery)
                        ->where('status', 'verified')
                        ->sum('volume_ml'),
                ],
                'alerts' => EmergencyAlertResource::collection($payload['alerts']),
                'commitments' => EmergencyCommitmentResource::collection($payload['commitments']),
                'current_admin' => AdminUserResource::make($admin->load('hospital.province', 'hospital.ward')),
            ],
        ]);
    }
}
