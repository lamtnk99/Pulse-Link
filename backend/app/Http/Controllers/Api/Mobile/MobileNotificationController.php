<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Http\Resources\MobileNotificationResource;
use App\Models\MobileNotification;
use App\Models\NotificationDevice;
use App\Models\NotificationPreference;
use App\Services\Mobile\MobileUserResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MobileNotificationController extends Controller
{
    public function __construct(
        private readonly MobileUserResolver $mobileUserResolver,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));

        return response()->json([
            'data' => MobileNotificationResource::collection(
                MobileNotification::query()
                    ->where('user_id', $user->id)
                    ->latest()
                    ->limit(50)
                    ->get()
            )->resolve(),
        ]);
    }

    public function markRead(Request $request, MobileNotification $notification): MobileNotificationResource
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));
        abort_unless((int) $notification->user_id === (int) $user->id, 403);

        $notification->update(['read_at' => $notification->read_at ?? now()]);

        return MobileNotificationResource::make($notification->refresh());
    }

    public function preferences(Request $request): JsonResponse
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));

        return response()->json([
            'data' => $this->preferencePayload(
                NotificationPreference::query()->firstOrCreate(['user_id' => $user->id])->refresh()
            ),
        ]);
    }

    public function updatePreferences(Request $request): JsonResponse
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));
        $payload = $request->validate([
            'sos_enabled' => ['sometimes', 'boolean'],
            'appointments_enabled' => ['sometimes', 'boolean'],
            'care_enabled' => ['sometimes', 'boolean'],
            'nearby_events_enabled' => ['sometimes', 'boolean'],
            'community_enabled' => ['sometimes', 'boolean'],
            'quiet_hours_start' => ['nullable', 'date_format:H:i'],
            'quiet_hours_end' => ['nullable', 'date_format:H:i'],
        ]);

        $preference = NotificationPreference::query()->firstOrCreate(['user_id' => $user->id])->refresh();
        $preference->update($payload);

        return response()->json(['data' => $this->preferencePayload($preference->refresh())]);
    }

    public function registerDevice(Request $request): JsonResponse
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));
        $payload = $request->validate([
            'token' => ['required', 'string', 'max:512'],
            'platform' => ['required', 'in:android,ios'],
            'app_version' => ['nullable', 'string', 'max:32'],
        ]);

        $device = NotificationDevice::query()->updateOrCreate(
            ['token' => $payload['token']],
            [
                'user_id' => $user->id,
                'platform' => $payload['platform'],
                'app_version' => $payload['app_version'] ?? null,
                'last_seen_at' => now(),
                'disabled_at' => null,
                'last_error' => null,
            ],
        );

        // Giữ token đơn cũ trong một giai đoạn để không làm đứt app đã phát hành.
        $user->update(['fcm_token' => $device->token]);

        return response()->json([
            'data' => [
                'id' => $device->id,
                'platform' => $device->platform,
                'enabled' => $device->disabled_at === null,
            ],
        ]);
    }

    public function removeDevice(Request $request): JsonResponse
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));
        $payload = $request->validate(['token' => ['required', 'string', 'max:512']]);

        $removed = NotificationDevice::query()
            ->where('user_id', $user->id)
            ->where('token', $payload['token'])
            ->delete();

        if ($user->fcm_token === $payload['token']) {
            $user->update(['fcm_token' => null]);
        }

        return response()->json(['data' => ['removed' => $removed > 0]]);
    }

    private function preferencePayload(NotificationPreference $preference): array
    {
        return [
            'sos_enabled' => $preference->sos_enabled,
            'appointments_enabled' => $preference->appointments_enabled,
            'care_enabled' => $preference->care_enabled,
            'nearby_events_enabled' => $preference->nearby_events_enabled,
            'community_enabled' => $preference->community_enabled,
            'quiet_hours_start' => $preference->quiet_hours_start,
            'quiet_hours_end' => $preference->quiet_hours_end,
        ];
    }
}
