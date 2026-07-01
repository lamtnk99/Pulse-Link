<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CommunityPostResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'slug' => $this->slug,
            'title' => $this->title,
            'excerpt' => $this->excerpt,
            'content' => $this->content,
            'image_url' => $this->image_url,
            'status' => $this->status,
            'published_at' => $this->published_at?->toIso8601String(),
            'audience_type' => $this->audience_type,
            'audience_label' => $this->audienceLabel(),
            'target_blood_type' => $this->target_blood_type,
            'target_hero_level' => $this->target_hero_level,
            'province_code' => $this->province_code,
            'province' => ProvinceResource::make($this->whenLoaded('province')),
            'ward_code' => $this->ward_code,
            'ward' => WardResource::make($this->whenLoaded('ward')),
            'hospital' => HospitalResource::make($this->whenLoaded('hospital')),
            'views_count' => $this->views_count,
            'shares_count' => $this->shares_count,
        ];
    }

    private function audienceLabel(): string
    {
        return match ($this->audience_type) {
            'blood_type' => 'Nhóm máu '.$this->target_blood_type,
            'hero_level' => 'Cấp '.$this->target_hero_level,
            'province' => $this->province?->full_name ?? 'Theo tỉnh/thành',
            default => 'Tất cả người dùng',
        };
    }
}
