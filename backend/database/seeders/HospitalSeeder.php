<?php

namespace Database\Seeders;

use App\Models\Hospital;
use Illuminate\Database\Seeder;

class HospitalSeeder extends Seeder
{
    public function run(): void
    {
        $hospitals = [
            [
                'name' => 'Bệnh viện Chợ Rẫy',
                'code' => 'CR-79',
                'province_code' => '79',
                'ward_code' => '27301',
                'address' => '201B Nguyễn Chí Thanh, TP. Hồ Chí Minh',
                'latitude' => 10.7565,
                'longitude' => 106.6594,
                'contact_phone' => '02838554137',
                'contact_email' => 'sos@choray.vn',
            ],
            [
                'name' => 'Bệnh viện Truyền máu Huyết học TP.HCM',
                'code' => 'TMHH-79',
                'province_code' => '79',
                'ward_code' => '27238',
                'address' => '118 Hồng Bàng, TP. Hồ Chí Minh',
                'latitude' => 10.7552,
                'longitude' => 106.6656,
                'contact_phone' => '02839557858',
                'contact_email' => 'dieuphoi@bthh.org.vn',
            ],
            [
                'name' => 'Bệnh viện Bạch Mai',
                'code' => 'BM-01',
                'province_code' => '01',
                'ward_code' => '00292',
                'address' => '78 Giải Phóng, Hà Nội',
                'latitude' => 21.0008,
                'longitude' => 105.8413,
                'contact_phone' => '02438693731',
                'contact_email' => 'sos@bachmai.vn',
            ],
            [
                'name' => 'Bệnh viện Trung ương Huế',
                'code' => 'TWH-46',
                'province_code' => '46',
                'ward_code' => '19753',
                'address' => '16 Lê Lợi, Huế',
                'latitude' => 16.4628,
                'longitude' => 107.5908,
                'contact_phone' => '02343822325',
                'contact_email' => 'sos@bvtwhue.vn',
            ],
            [
                'name' => 'Bệnh viện Đà Nẵng',
                'code' => 'DN-48',
                'province_code' => '48',
                'ward_code' => '20275',
                'address' => '124 Hải Phòng, Đà Nẵng',
                'latitude' => 16.0718,
                'longitude' => 108.2140,
                'contact_phone' => '02363821218',
                'contact_email' => 'sos@dananghospital.vn',
            ],
            [
                'name' => 'Bệnh viện Đa khoa Trung ương Cần Thơ',
                'code' => 'CT-92',
                'province_code' => '92',
                'ward_code' => '31135',
                'address' => '315 Nguyễn Văn Linh, Cần Thơ',
                'latitude' => 10.0306,
                'longitude' => 105.7683,
                'contact_phone' => '02923732920',
                'contact_email' => 'sos@bvtwct.vn',
            ],
        ];

        foreach ($hospitals as $hospital) {
            Hospital::query()->updateOrCreate(
                ['code' => $hospital['code']],
                [...$hospital, 'is_active' => true],
            );
        }
    }
}
