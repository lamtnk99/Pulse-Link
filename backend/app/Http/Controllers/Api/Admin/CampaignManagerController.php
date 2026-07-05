<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\DonationCampaign;
use App\Models\CampaignDonation;
use App\Services\Admin\AdminUserResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CampaignManagerController extends Controller
{
    public function __construct(
        private readonly AdminUserResolver $adminUserResolver
    ) {}

    public function index(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);

        $campaigns = DonationCampaign::query()
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($campaign) {
                // Attach stats
                $campaign->total_donors = $campaign->donations()->where('payment_status', 'success')->count();
                return [
                    'id' => $campaign->id,
                    'public_id' => $campaign->public_id,
                    'title' => $campaign->title,
                    'description' => $campaign->description,
                    'image_url' => $campaign->image_url,
                    'type' => $campaign->type,
                    'target_amount' => (float) $campaign->target_amount,
                    'current_amount' => (float) $campaign->current_amount,
                    'target_points' => (int) $campaign->target_points,
                    'current_points' => (int) $campaign->current_points,
                    'status' => $campaign->status,
                    'expires_at' => $campaign->expires_at?->toIso8601String(),
                    'total_donors' => $campaign->total_donors,
                    'created_at' => $campaign->created_at?->toIso8601String(),
                ];
            });

        return response()->json(['data' => $campaigns]);
    }

    public function store(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);

        $payload = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
            'image_url' => ['nullable', 'url'],
            'type' => ['required', 'string', 'in:financial,points,both'],
            'target_amount' => ['required_if:type,financial,both', 'numeric', 'min:0'],
            'target_points' => ['required_if:type,points,both', 'integer', 'min:0'],
            'expires_at' => ['nullable', 'date'],
        ]);

        $campaign = DonationCampaign::create([
            'title' => $payload['title'],
            'description' => $payload['description'],
            'image_url' => $payload['image_url'] ?? null,
            'type' => $payload['type'],
            'target_amount' => $payload['target_amount'] ?? 0,
            'current_amount' => 0,
            'target_points' => $payload['target_points'] ?? 0,
            'current_points' => 0,
            'status' => 'active',
            'expires_at' => $payload['expires_at'] ?? null,
        ]);

        return response()->json([
            'message' => 'Tạo chiến dịch quyên góp thành công!',
            'data' => $campaign,
        ], 211); // Standard created status or 201
    }

    public function show(Request $request, $id): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);

        $campaign = DonationCampaign::query()->findOrFail($id);

        return response()->json(['data' => $campaign]);
    }

    public function update(Request $request, $id): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);

        $campaign = DonationCampaign::query()->findOrFail($id);

        $payload = $request->validate([
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['sometimes', 'required', 'string'],
            'image_url' => ['nullable', 'url'],
            'type' => ['sometimes', 'required', 'string', 'in:financial,points,both'],
            'target_amount' => ['sometimes', 'numeric', 'min:0'],
            'target_points' => ['sometimes', 'integer', 'min:0'],
            'status' => ['sometimes', 'required', 'string', 'in:active,completed,cancelled'],
            'expires_at' => ['nullable', 'date'],
        ]);

        $campaign->update($payload);

        return response()->json([
            'message' => 'Cập nhật chiến dịch thành công!',
            'data' => $campaign,
        ]);
    }

    public function destroy(Request $request, $id): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);

        $campaign = DonationCampaign::query()->findOrFail($id);
        $campaign->delete();

        return response()->json(['message' => 'Xóa chiến dịch thành công!']);
    }

    public function transactions(Request $request, $id): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);

        $campaign = DonationCampaign::query()->findOrFail($id);

        $donations = $campaign->donations()
            ->with('user')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(fn($d) => [
                'id' => $d->id,
                'amount' => (float) $d->amount,
                'points' => (int) $d->points,
                'payment_method' => $d->payment_method,
                'payment_status' => $d->payment_status,
                'transaction_id' => $d->transaction_id,
                'donor_name' => $d->is_anonymous ? 'Hiệp sĩ ẩn danh' : $d->donor_name,
                'message' => $d->message,
                'is_anonymous' => $d->is_anonymous,
                'created_at' => $d->created_at?->toIso8601String(),
                'user' => $d->user ? [
                    'id' => $d->user->id,
                    'name' => $d->user->name,
                    'email' => $d->user->email,
                ] : null,
            ]);

        return response()->json(['data' => $donations]);
    }
}
