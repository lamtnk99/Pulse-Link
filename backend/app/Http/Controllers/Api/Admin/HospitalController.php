<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\HospitalResource;
use App\Models\Hospital;
use App\Services\Admin\AdminUserResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class HospitalController extends Controller
{
    public function __construct(
        private readonly AdminUserResolver $adminUserResolver,
    ) {}

    public function index(Request $request)
    {
        $admin = $this->adminUserResolver->resolve($request);
        $perPage = min(max($request->integer('per_page', 10), 1), 50);
        $keyword = trim((string) $request->query('q', ''));
        $status = $request->query('status');

        return HospitalResource::collection(
            Hospital::query()
                ->with('province', 'ward')
                ->when($admin->role !== 'system_admin', fn ($query) => $query->whereKey($admin->hospital_id))
                ->when($keyword !== '', function ($query) use ($keyword): void {
                    $query->where(function ($query) use ($keyword): void {
                        $query
                            ->where('name', 'like', "%{$keyword}%")
                            ->orWhere('code', 'like', "%{$keyword}%")
                            ->orWhere('address', 'like', "%{$keyword}%")
                            ->orWhere('contact_phone', 'like', "%{$keyword}%")
                            ->orWhere('contact_email', 'like', "%{$keyword}%");
                    });
                })
                ->when($status === 'active', fn ($query) => $query->where('is_active', true))
                ->when($status === 'inactive', fn ($query) => $query->where('is_active', false))
                ->orderByDesc('is_active')
                ->orderBy('name')
                ->paginate($perPage)
        );
    }

    public function store(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($admin->role === 'system_admin', 403);

        $hospital = Hospital::query()->create($this->validatedPayload($request));

        return response()->json([
            'data' => HospitalResource::make($hospital->load('province', 'ward')),
        ], 201);
    }

    public function update(Request $request, Hospital $hospital): HospitalResource
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($admin->role === 'system_admin', 403);

        $hospital->update($this->validatedPayload($request, partial: true, hospital: $hospital));

        return HospitalResource::make($hospital->refresh()->load('province', 'ward'));
    }

    public function destroy(Request $request, Hospital $hospital): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($admin->role === 'system_admin', 403);

        $hospital->update(['is_active' => false]);

        return response()->json(status: 204);
    }

    private function validatedPayload(Request $request, bool $partial = false, ?Hospital $hospital = null): array
    {
        $prefix = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'name' => [$prefix, 'string', 'max:255'],
            'code' => [$prefix, 'string', 'max:32', Rule::unique('hospitals', 'code')->ignore($hospital?->id)],
            'province_code' => [$prefix, 'string', 'size:2', 'exists:provinces,code'],
            'ward_code' => ['nullable', 'string', 'size:5', 'exists:wards,code'],
            'address' => [$prefix, 'string', 'max:255'],
            'latitude' => [$prefix, 'numeric', 'between:-90,90'],
            'longitude' => [$prefix, 'numeric', 'between:-180,180'],
            'contact_phone' => ['nullable', 'string', 'max:24'],
            'contact_email' => ['nullable', 'email', 'max:255'],
            'is_active' => ['sometimes', 'boolean'],
        ]);
    }
}
