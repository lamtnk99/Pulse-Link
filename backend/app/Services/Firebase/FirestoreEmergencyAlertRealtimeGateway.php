<?php

namespace App\Services\Firebase;

use App\Domain\Blood\BloodCompatibility;
use App\Models\EmergencyAlert;
use App\Services\Contracts\EmergencyAlertRealtimeGateway;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FirestoreEmergencyAlertRealtimeGateway implements EmergencyAlertRealtimeGateway
{
    public function __construct(
        private readonly BloodCompatibility $bloodCompatibility,
    ) {}

    public function publish(EmergencyAlert $alert): void
    {
        $projectId = config('services.firebase.project_id');
        $accessToken = $this->resolveAccessToken();

        if (! $projectId || ! $accessToken) {
            Log::warning('Firestore SOS mirror skipped because Firebase credentials are not configured.', [
                'alert_id' => $alert->public_id,
            ]);

            return;
        }

        $alert->loadMissing('hospital');
        $endpoint = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/sos_alerts/{$alert->public_id}";

        try {
            Http::withToken($accessToken)->patch($endpoint, [
                'fields' => $this->firestoreFields($alert),
            ])->throw();
        } catch (RequestException $exception) {
            Log::error('Firestore SOS mirror failed.', [
                'alert_id' => $alert->public_id,
                'status' => $exception->response?->status(),
                'body' => $exception->response?->body(),
            ]);
        }
    }

    private function firestoreFields(EmergencyAlert $alert): array
    {
        $hospital = $alert->hospital;

        return [
            'id' => ['stringValue' => $alert->public_id],
            'active' => ['booleanValue' => $alert->status === 'active'],
            'blood_types' => [
                'arrayValue' => [
                    'values' => collect($this->bloodCompatibility->compatibleDonorTypesForRecipient($alert->required_blood_type))
                        ->map(fn (string $bloodType): array => ['stringValue' => $bloodType])
                        ->values()
                        ->all(),
                ],
            ],
            'hospital_name' => ['stringValue' => $hospital->name],
            'hospital_address' => ['stringValue' => $hospital->address],
            'hospital_province_code' => ['stringValue' => $hospital->province_code],
            'hospital_location' => [
                'mapValue' => [
                    'fields' => [
                        'latitude' => ['doubleValue' => $hospital->latitude],
                        'longitude' => ['doubleValue' => $hospital->longitude],
                    ],
                ],
            ],
            'required_blood_type' => ['stringValue' => $alert->required_blood_type],
            'level' => ['stringValue' => $alert->level],
            'units_needed' => ['integerValue' => $alert->units_needed],
            'created_at' => ['timestampValue' => $alert->created_at?->toIso8601String() ?? now()->toIso8601String()],
            'expires_at' => ['timestampValue' => $alert->expires_at->toIso8601String()],
            'message' => ['stringValue' => $alert->message],
        ];
    }

    private function resolveAccessToken(): ?string
    {
        return env('FIREBASE_ACCESS_TOKEN');
    }
}
