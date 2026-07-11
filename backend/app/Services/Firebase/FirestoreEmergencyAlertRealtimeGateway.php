<?php

namespace App\Services\Firebase;

use App\Domain\Blood\BloodCompatibility;
use App\Models\EmergencyAlert;
use App\Services\Contracts\EmergencyAlertRealtimeGateway;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class FirestoreEmergencyAlertRealtimeGateway implements EmergencyAlertRealtimeGateway
{
    public function __construct(
        private readonly BloodCompatibility $bloodCompatibility,
    ) {}

    public function publish(EmergencyAlert $alert): void
    {
        $projectId = config('services.firebase.project_id');
        try {
            $accessToken = $this->resolveAccessToken();
        } catch (\Throwable $exception) {
            Log::warning('Firestore SOS mirror skipped because Firebase credentials could not be resolved.', [
                'alert_id' => $alert->public_id,
                'error' => $exception->getMessage(),
            ]);

            return;
        }

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
            'accepting_commitments' => ['booleanValue' => $alert->acceptsNewCommitments()],
            'compatibility_mode' => ['stringValue' => $alert->compatibility_mode ?? EmergencyAlert::COMPATIBILITY_COMPATIBLE],
            'blood_types' => [
                'arrayValue' => [
                    'values' => collect($this->dispatchBloodTypes($alert))
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
            'broadcast_stopped_at' => $alert->broadcast_stopped_at
                ? ['timestampValue' => $alert->broadcast_stopped_at->toIso8601String()]
                : ['nullValue' => null],
            'message' => ['stringValue' => $alert->message],
        ];
    }

    private function dispatchBloodTypes(EmergencyAlert $alert): array
    {
        if (($alert->compatibility_mode ?? EmergencyAlert::COMPATIBILITY_COMPATIBLE) === EmergencyAlert::COMPATIBILITY_EXACT) {
            return [$alert->required_blood_type];
        }

        return $this->bloodCompatibility->compatibleDonorTypesForRecipient($alert->required_blood_type);
    }

    private function resolveAccessToken(): ?string
    {
        if ($token = env('FIREBASE_ACCESS_TOKEN')) {
            return $token;
        }

        $serviceAccount = $this->serviceAccount();
        if ($serviceAccount === null) {
            return null;
        }

        $cacheKey = 'firebase.firestore.access-token.'.sha1($serviceAccount['client_email']);

        return Cache::remember($cacheKey, now()->addMinutes(50), function () use ($serviceAccount): ?string {
            $issuedAt = time();
            $header = $this->base64Url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $claims = $this->base64Url(json_encode([
                'iss' => $serviceAccount['client_email'],
                'scope' => 'https://www.googleapis.com/auth/datastore',
                'aud' => $serviceAccount['token_uri'],
                'iat' => $issuedAt,
                'exp' => $issuedAt + 3600,
            ]));
            $unsignedToken = $header.'.'.$claims;
            $signature = '';

            if (! openssl_sign($unsignedToken, $signature, $serviceAccount['private_key'], OPENSSL_ALGO_SHA256)) {
                throw new RuntimeException('Không thể ký JWT cho Firebase service account.');
            }

            $response = Http::asForm()->post($serviceAccount['token_uri'], [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $unsignedToken.'.'.$this->base64Url($signature),
            ])->throw();

            return $response->json('access_token');
        });
    }

    /** @return array{client_email: string, private_key: string, token_uri: string}|null */
    private function serviceAccount(): ?array
    {
        $json = config('services.firebase.service_account_json');
        $path = config('services.firebase.service_account_path');
        if (! $json && $path && is_file($path)) {
            $json = file_get_contents($path);
        }

        $account = is_string($json) ? json_decode($json, true) : null;
        if (is_array($account) && filled($account['client_email'] ?? null) && filled($account['private_key'] ?? null)) {
            return [
                'client_email' => $account['client_email'],
                'private_key' => str_replace('\\n', "\n", $account['private_key']),
                'token_uri' => $account['token_uri'] ?? 'https://oauth2.googleapis.com/token',
            ];
        }

        $clientEmail = config('services.firebase.client_email');
        $privateKey = config('services.firebase.private_key');
        if (! $clientEmail || ! $privateKey) {
            return null;
        }

        return [
            'client_email' => $clientEmail,
            'private_key' => str_replace('\\n', "\n", $privateKey),
            'token_uri' => 'https://oauth2.googleapis.com/token',
        ];
    }

    private function base64Url(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}
