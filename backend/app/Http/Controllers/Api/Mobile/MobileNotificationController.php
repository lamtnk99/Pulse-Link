<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Http\Resources\MobileNotificationResource;
use App\Models\MobileNotification;
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
}
