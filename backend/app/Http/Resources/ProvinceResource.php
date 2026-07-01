<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProvinceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'code' => $this->code,
            'name' => $this->name,
            'name_en' => $this->name_en,
            'full_name' => $this->full_name,
            'full_name_en' => $this->full_name_en,
            'code_name' => $this->code_name,
            'centroid' => [
                'latitude' => $this->centroid_latitude,
                'longitude' => $this->centroid_longitude,
            ],
        ];
    }
}
