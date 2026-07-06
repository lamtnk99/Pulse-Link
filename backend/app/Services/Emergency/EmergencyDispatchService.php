<?php

namespace App\Services\Emergency;

use App\Domain\Blood\BloodCompatibility;
use App\Domain\Emergency\DispatchWavePolicy;
use App\Events\EmergencyAlertActivated;
use App\Models\EmergencyAlert;
use App\Models\EmergencyAlertRecipient;
use App\Models\Hospital;
use App\Repositories\Contracts\DonorRepository;
use App\Repositories\Contracts\EmergencyAlertRepository;
use App\Services\Contracts\EmergencyAlertRealtimeGateway;
use App\Services\Contracts\PushNotificationGateway;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class EmergencyDispatchService
{
    public function __construct(
        private readonly BloodCompatibility $bloodCompatibility,
        private readonly DispatchWavePolicy $dispatchWavePolicy,
        private readonly DonorRepository $donors,
        private readonly EmergencyAlertRepository $alerts,
        private readonly PushNotificationGateway $pushNotifications,
        private readonly EmergencyAlertRealtimeGateway $realtimeGateway,
    ) {}

    public function activate(Hospital $hospital, array $payload): EmergencyAlert
    {
        $compatibleTypes = $this->bloodCompatibility
            ->compatibleDonorTypesForRecipient($payload['required_blood_type']);

        $candidateDonors = $this->donors->compatibleActiveDonors($compatibleTypes);
        $dispatch = $this->dispatchWavePolicy->selectRecipients(
            donors: $candidateDonors,
            hospital: $hospital,
            level: $payload['level'],
        );

        /** @var EmergencyAlert $alert */
        $alert = DB::transaction(function () use ($hospital, $payload, $dispatch): EmergencyAlert {
            $alert = $this->alerts->createActiveAlert([
                ...$payload,
                'expires_at' => Carbon::parse($payload['expires_at']),
            ], $hospital);

            $recipients = collect($dispatch['recipients'])
                ->map(fn ($candidate): EmergencyAlertRecipient => $alert->recipients()->create([
                    'user_id' => $candidate->donor->id,
                    'wave' => $candidate->wave,
                    'distance_km' => $candidate->distanceKm,
                    'notified_at' => now(),
                ]));

            $alert->update([
                'dispatch_summary' => [
                    ...$dispatch['summary'],
                    'recipient_count' => $recipients->count(),
                ],
            ]);

            return $alert->load('hospital', 'recipients.donor');
        });

        $this->pushNotifications->sendEmergencyAlert($alert, $alert->recipients);
        $this->realtimeGateway->publish($alert);
        $this->broadcastAlert($alert);

        return $alert;
    }

    public function activeDashboardPayload(?int $hospitalId = null): array
    {
        $alerts = EmergencyAlert::query()
            ->with(['hospital.province', 'hospital.ward', 'recipients.donor.province', 'commitments.donor.province', 'commitments.bloodJourney.steps'])
            ->whereIn('status', ['active', 'fulfilled'])
            ->when($hospitalId, fn ($query) => $query->where('hospital_id', $hospitalId))
            ->latest()
            ->limit(30)
            ->get();

        $commitments = $alerts->flatMap(fn (EmergencyAlert $alert): Collection => $alert->commitments)
            ->each(fn ($commitment) => $commitment->loadMissing('donor.province', 'donor.ward', 'alert'));

        return [
            'stats' => [
                'active_alerts' => $alerts->where('status', 'active')->count(),
                'notified_donors' => $alerts->where('status', 'active')->sum(fn (EmergencyAlert $alert) => $alert->recipients->count()),
                'committed_donors' => $commitments->where('status', '!=', 'cancelled')->count(),
                'donated_donors' => $commitments->where('status', 'donated')->count(),
            ],
            'alerts' => $alerts,
            'commitments' => $commitments->values(),
        ];
    }

    private function broadcastAlert(EmergencyAlert $alert): void
    {
        try {
            broadcast(new EmergencyAlertActivated($alert));
        } catch (Throwable $exception) {
            Log::warning('Emergency alert broadcast skipped.', [
                'alert_id' => $alert->public_id,
                'message' => $exception->getMessage(),
            ]);
        }
    }
}
