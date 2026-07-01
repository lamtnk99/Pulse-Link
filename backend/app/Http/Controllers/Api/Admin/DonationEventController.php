<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\DonationEventDetailResource;
use App\Models\DonationEvent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DonationEventController extends Controller
{
    public function index()
    {
        return DonationEventDetailResource::collection(
            DonationEvent::query()
                ->with('appointments', 'province', 'ward', 'hospital.province', 'hospital.ward')
                ->orderBy('starts_at')
                ->get()
        );
    }

    public function store(Request $request): JsonResponse
    {
        $payload = $this->validatedPayload($request);
        $event = DonationEvent::query()->create([
            ...$payload,
            'booked_count' => 0,
        ]);

        return response()->json([
            'data' => DonationEventDetailResource::make(
                $event->load('appointments', 'province', 'ward', 'hospital.province', 'hospital.ward')
            ),
        ], 201);
    }

    public function update(Request $request, DonationEvent $event): DonationEventDetailResource
    {
        $event->update($this->validatedPayload($request, partial: true));

        return DonationEventDetailResource::make(
            $event->refresh()->load('appointments', 'province', 'ward', 'hospital.province', 'hospital.ward')
        );
    }

    public function destroy(DonationEvent $event): JsonResponse
    {
        $event->delete();

        return response()->json(status: 204);
    }

    private function validatedPayload(Request $request, bool $partial = false): array
    {
        $prefix = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'hospital_id' => ['nullable', 'integer', 'exists:hospitals,id'],
            'title' => [$prefix, 'string', 'max:255'],
            'organizer' => [$prefix, 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'starts_at' => [$prefix, 'date'],
            'ends_at' => [$prefix, 'date', 'after:starts_at'],
            'location_name' => [$prefix, 'string', 'max:255'],
            'province_code' => [$prefix, 'string', 'size:2', 'exists:provinces,code'],
            'ward_code' => ['nullable', 'string', 'size:5', 'exists:wards,code'],
            'latitude' => [$prefix, 'numeric', 'between:-90,90'],
            'longitude' => [$prefix, 'numeric', 'between:-180,180'],
            'urgency' => ['sometimes', 'in:normal,high'],
            'image_url' => ['nullable', 'string', 'max:2048'],
            'capacity' => ['sometimes', 'integer', 'min:1', 'max:5000'],
            'is_published' => ['sometimes', 'boolean'],
        ]);
    }
}
