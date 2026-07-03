<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\AdminUserResource;
use App\Models\User;
use App\Services\Admin\AdminUserResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class StaffController extends Controller
{
    public function __construct(
        private readonly AdminUserResolver $adminUserResolver,
    ) {}

    public function index(Request $request)
    {
        $admin = $this->adminUserResolver->resolve($request);

        return AdminUserResource::collection(
            User::query()
                ->with('hospital.province', 'hospital.ward')
                ->whereIn('role', ['system_admin', 'hospital_staff', 'hospital_admin'])
                ->when($admin->role !== 'system_admin', fn ($query) => $query->where('hospital_id', $admin->hospital_id))
                ->orderByRaw("case when role = 'system_admin' then 0 else 1 end")
                ->orderBy('name')
                ->get()
        );
    }

    public function store(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'staff.manage'), 403);

        $payload = $this->validatedPayload($request);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $payload['hospital_id'] ?? null), 403);

        $user = User::query()->create([
            ...$payload,
            'role' => 'hospital_staff',
            'password' => Hash::make($payload['password'] ?? 'password'),
            'last_seen_at' => now(),
        ]);

        return response()->json([
            'data' => AdminUserResource::make($user->load('hospital.province', 'hospital.ward')),
        ], 201);
    }

    public function update(Request $request, User $staff): AdminUserResource
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'staff.manage'), 403);
        abort_unless(in_array($staff->role, ['hospital_staff', 'hospital_admin'], true), 422);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $staff->hospital_id), 403);

        $payload = $this->validatedPayload($request, partial: true, staff: $staff);
        if (array_key_exists('hospital_id', $payload)) {
            abort_unless($this->adminUserResolver->canAccessHospital($admin, $payload['hospital_id']), 403);
        }

        if (! empty($payload['password'])) {
            $payload['password'] = Hash::make($payload['password']);
        } else {
            unset($payload['password']);
        }

        $staff->update($payload);

        return AdminUserResource::make($staff->refresh()->load('hospital.province', 'hospital.ward'));
    }

    public function destroy(Request $request, User $staff): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($this->adminUserResolver->hasPermission($admin, 'staff.manage'), 403);
        abort_unless(in_array($staff->role, ['hospital_staff', 'hospital_admin'], true), 422);
        abort_unless($this->adminUserResolver->canAccessHospital($admin, $staff->hospital_id), 403);

        $staff->delete();

        return response()->json(status: 204);
    }

    private function validatedPayload(Request $request, bool $partial = false, ?User $staff = null): array
    {
        $prefix = $partial ? 'sometimes' : 'required';
        $emailRule = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'name' => [$prefix, 'string', 'max:255'],
            'email' => [$emailRule, 'email', 'max:255', Rule::unique('users', 'email')->ignore($staff?->id)],
            'phone' => ['nullable', 'string', 'max:24'],
            'hospital_id' => [$prefix, 'integer', 'exists:hospitals,id'],
            'permissions' => ['sometimes', 'array'],
            'permissions.*' => ['string', 'in:dashboard.view,sos.activate,events.manage,posts.manage,staff.manage'],
            'password' => ['nullable', 'string', 'min:6'],
            'last_seen_at' => ['nullable', 'date'],
        ]);
    }
}
