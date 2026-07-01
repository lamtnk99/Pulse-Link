<?php

namespace App\Services\Firebase;

use App\Models\EmergencyAlert;
use App\Services\Contracts\PushNotificationGateway;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmHttpV1PushNotificationGateway implements PushNotificationGateway
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

    private function resolveAccessToken(): ?string
    {
        if ($token = env('FIREBASE_ACCESS_TOKEN')) {
            return $token;
        }

        $clientEmail = config('services.firebase.client_email');
        $privateKey = config('services.firebase.private_key');

        if (! $clientEmail || ! $privateKey) {
            return null;
        }

        Log::notice('FIREBASE_ACCESS_TOKEN not set. Configure a token service or scheduled token refresh for production.');

        return null;
    }
}
