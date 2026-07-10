<?php

namespace App\Services\Firebase;

use App\Models\EmergencyAlert;
use App\Models\MobileNotification;
use App\Models\NotificationDevice;
use App\Services\Contracts\MobilePushNotificationGateway;
use App\Services\Contracts\PushNotificationGateway;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

class FcmHttpV1PushNotificationGateway implements MobilePushNotificationGateway, PushNotificationGateway
{
    public function sendEmergencyAlert(EmergencyAlert $alert, Collection $recipients): void
    {
        $projectId = config('services.firebase.project_id');
        $endpoint = config('services.firebase.messaging_endpoint')
            ?: ($projectId ? "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send" : null);
        $accessToken = $this->resolveAccessToken();

        if (! $endpoint || ! $accessToken) {
            Log::warning('FCM skipped because Firebase credentials are not configured.', [
                'alert_id' => $alert->public_id,
                'recipient_count' => $recipients->count(),
            ]);

            return;
        }

        foreach ($recipients as $recipient) {
            $token = $recipient->donor->fcm_token;
            if (! $token) {
                continue;
            }

            try {
                Http::withToken($accessToken)->post($endpoint, [
                    'message' => [
                        'token' => $token,
                        'notification' => [
                            'title' => "Pulse Link SOS {$alert->required_blood_type}",
                            'body' => $alert->message,
                        ],
                        'data' => [
                            'type' => 'emergency_alert',
                            'alert_id' => $alert->public_id,
                            'wave' => $recipient->wave,
                            'distance_km' => (string) $recipient->distance_km,
                        ],
                    ],
                ])->throw();
            } catch (RequestException $exception) {
                Log::error('FCM emergency push failed.', [
                    'alert_id' => $alert->public_id,
                    'recipient_id' => $recipient->id,
                    'status' => $exception->response?->status(),
                    'body' => $exception->response?->body(),
                ]);
            }
        }
    }

    public function send(NotificationDevice $device, MobileNotification $notification, bool $isSos): array
    {
        $endpoint = $this->endpoint();
        $accessToken = $this->resolveAccessToken();
        if (! $endpoint || ! $accessToken) {
            Log::notice('FCM mobile push skipped because Firebase credentials are not configured.', [
                'notification_id' => $notification->id,
                'device_id' => $device->id,
            ]);

            return ['provider_message_id' => null, 'skipped' => true];
        }

        $response = Http::withToken($accessToken)
            ->post($endpoint, ['message' => $this->messagePayload($device, $notification, $isSos)])
            ->throw();

        return [
            'provider_message_id' => $response->json('name'),
            'skipped' => false,
        ];
    }

    private function messagePayload(NotificationDevice $device, MobileNotification $notification, bool $isSos): array
    {
        $data = [
            'notification_id' => (string) $notification->id,
            'type' => $notification->type,
        ];

        foreach (($notification->payload ?? []) as $key => $value) {
            if (is_scalar($value) || $value === null) {
                $data[(string) $key] = (string) $value;
            } else {
                $data[(string) $key] = json_encode($value, JSON_UNESCAPED_UNICODE) ?: '';
            }
        }

        return [
            'token' => $device->token,
            'notification' => [
                'title' => $notification->title,
                'body' => $notification->body,
            ],
            'data' => $data,
            'android' => [
                'priority' => $isSos ? 'high' : 'normal',
                'notification' => [
                    'channel_id' => $isSos ? 'pulse_link_sos' : 'pulse_link_general',
                    'sound' => 'default',
                ],
            ],
            'apns' => [
                'headers' => [
                    'apns-push-type' => 'alert',
                    'apns-priority' => $isSos ? '10' : '5',
                ],
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                        // Time Sensitive is used only for a matching SOS alert.
                        // It does not request or assume Apple's Critical Alerts entitlement.
                        ...($isSos ? ['interruption-level' => 'time-sensitive'] : []),
                    ],
                ],
            ],
        ];
    }

    private function endpoint(): ?string
    {
        $projectId = config('services.firebase.project_id');

        return config('services.firebase.messaging_endpoint')
            ?: ($projectId ? "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send" : null);
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

        $cacheKey = 'firebase.fcm.access-token.'.sha1($serviceAccount['client_email']);

        return Cache::remember($cacheKey, now()->addMinutes(50), function () use ($serviceAccount): ?string {
            $issuedAt = time();
            $header = $this->base64Url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $claims = $this->base64Url(json_encode([
                'iss' => $serviceAccount['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
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
