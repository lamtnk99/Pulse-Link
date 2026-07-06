<?php

namespace App\Repositories\Eloquent;

use App\Models\User;
use App\Repositories\Contracts\DonorRepository;
use Illuminate\Support\Collection;

class EloquentDonorRepository implements DonorRepository
{
    public function compatibleActiveDonors(array $bloodTypes): Collection
    {
        // Không lọc theo fcm_token: donor vẫn là ứng viên nhận tin trong app dù chưa
        // đăng ký push (đặc biệt là donor đăng nhập qua web). Push gateway đã tự bỏ
        // qua donor thiếu token. Chỉ cần toạ độ để tính khoảng cách theo wave.
        return User::query()
            ->where('role', 'donor')
            ->whereIn('blood_type', $bloodTypes)
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->get();
    }
}
