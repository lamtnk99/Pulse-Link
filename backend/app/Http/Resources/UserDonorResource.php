<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserDonorResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'blood_type' => $this->blood_type,
            'hero_level' => $this->hero_level,
            'badge_title' => $this->badge_title,
            'total_donations' => $this->total_donations,
            'points' => $this->points,
            'province_code' => $this->province_code,
            'province' => ProvinceResource::make($this->whenLoaded('province')),
            'ward_code' => $this->ward_code,
            'ward' => WardResource::make($this->whenLoaded('ward')),
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'last_seen_at' => $this->last_seen_at?->toIso8601String(),
        ];
    }
}
