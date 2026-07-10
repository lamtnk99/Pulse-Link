<?php

namespace App\Services\Mobile;

use App\Models\MobileNotification;
use App\Models\NotificationDelivery;
use App\Models\NotificationPreference;
use App\Services\Contracts\MobilePushNotificationGateway;
use Carbon\CarbonImmutable;
use Throwable;

class MobilePushNotificationDispatcher
{
    public function __construct(private readonly MobilePushNotificationGateway $gateway) {}

    public function dispatch(MobileNotification $notification): void
    {
        $notification->loadMissing('user.notificationDevices', 'user.notificationPreference');
        $user = $notification->user;
        if ($user === null) {
            return;
        }

        $preference = $user->notificationPreference
            ?? NotificationPreference::query()->firstOrCreate(['user_id' => $user->id])->refresh();
        $isSos = $this->isSos($notification);

        if (! $this->isEnabled($preference, $notification) || (! $isSos && $this->isQuietHours($preference))) {
            NotificationDelivery::query()->create([
                'mobile_notification_id' => $notification->id,
                'status' => 'skipped',
                'failure_code' => 'preference',
                'failure_message' => 'Người dùng đã tắt nhóm thông báo này hoặc đang trong giờ yên lặng.',
            ]);

            return;
        }

        foreach ($user->notificationDevices->whereNull('disabled_at') as $device) {
            $delivery = NotificationDelivery::query()->create([
                'mobile_notification_id' => $notification->id,
                'notification_device_id' => $device->id,
                'status' => 'pending',
            ]);

            try {
                $result = $this->gateway->send($device, $notification, $isSos);
                $delivery->update([
                    'status' => ($result['skipped'] ?? false) ? 'skipped' : 'sent',
                    'provider_message_id' => $result['provider_message_id'],
                    'sent_at' => ($result['skipped'] ?? false) ? null : now(),
                ]);
                $device->update(['last_seen_at' => now(), 'last_error' => null]);
            } catch (Throwable $exception) {
                $message = $exception->getMessage();
                $delivery->update([
                    'status' => 'failed',
                    'failure_code' => $this->failureCode($message),
                    'failure_message' => mb_substr($message, 0, 4000),
                ]);
                $device->update([
                    'last_error' => mb_substr($message, 0, 1000),
                    'disabled_at' => $this->isInvalidToken($message) ? now() : $device->disabled_at,
                ]);
            }
        }
    }

    private function isEnabled(NotificationPreference $preference, MobileNotification $notification): bool
    {
        return match ($this->category($notification)) {
            'sos' => $preference->sos_enabled,
            'appointments' => $preference->appointments_enabled,
            'care' => $preference->care_enabled,
            'nearby_events' => $preference->nearby_events_enabled,
            'community' => $preference->community_enabled,
            default => true,
        };
    }

    private function category(MobileNotification $notification): string
    {
        return match ($notification->type) {
            'emergency_alert', 'sos_fulfilled', 'sos_commitment_cancelled' => 'sos',
            'appointment_reminder', 'appointment_confirmed', 'pre_donation_guidance' => 'appointments',
            'donation_verified', 'post_donation_checkup', 'blood_journey_completed', 'donation_deferred' => 'care',
            'nearby_donation_event' => 'nearby_events',
            'community_impact', 'campaign_update' => 'community',
            default => 'system',
        };
    }

    private function isSos(MobileNotification $notification): bool
    {
        return $this->category($notification) === 'sos';
    }

    private function isQuietHours(NotificationPreference $preference): bool
    {
        if (! $preference->quiet_hours_start || ! $preference->quiet_hours_end) {
            return false;
        }

        $now = CarbonImmutable::now(config('app.timezone'))->format('H:i:s');
        $start = $preference->quiet_hours_start;
        $end = $preference->quiet_hours_end;

        return $start <= $end
            ? $now >= $start && $now < $end
            : $now >= $start || $now < $end;
    }

    private function isInvalidToken(string $message): bool
    {
        return str_contains($message, 'UNREGISTERED') || str_contains($message, 'registration-token-not-registered');
    }

    private function failureCode(string $message): string
    {
        return $this->isInvalidToken($message) ? 'invalid_token' : 'provider_error';
    }
}
