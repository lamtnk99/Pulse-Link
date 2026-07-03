<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AdminUserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'role' => $this->role,
            'hospital_id' => $this->hospital_id,
            'hospital' => HospitalResource::make($this->whenLoaded('hospital')),
            'permissions' => $this->permissions ?? [],
            'active' => $this->last_seen_at !== null,
            'scope_label' => $this->role === 'system_admin'
                ? 'Toàn hệ thống'
                : ($this->hospital?->name ?? 'Chưa gán bệnh viện'),
        ];
    }
}
