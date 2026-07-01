<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HospitalResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'code' => $this->code,
            'province_code' => $this->province_code,
            'province' => ProvinceResource::make($this->whenLoaded('province')),
            'ward_code' => $this->ward_code,
            'ward' => WardResource::make($this->whenLoaded('ward')),
            'address' => $this->address,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'contact_phone' => $this->contact_phone,
            'contact_email' => $this->contact_email,
            'is_active' => $this->is_active,
        ];
    }
}
