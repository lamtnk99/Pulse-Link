<?php

namespace Database\Seeders;

use App\Models\DonationHistory;
use App\Models\Hospital;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DonorSeeder extends Seeder
{
    public function run(): void
    {
        $hospital = Hospital::query()->where('code', 'CR-79')->firstOrFail();
        $bloodCenter = Hospital::query()->where('code', 'TMHH-79')->firstOrFail();
        $bachMai = Hospital::query()->where('code', 'BM-01')->firstOrFail();
        $staffHospitals = Hospital::query()
            ->whereIn('code', [
                'TMHH-79',
                'BM-01',
                'VD-01',
                'QD108-01',
                'TWH-46',
                'DN-48',
                'UMC-79',
                'ND1-79',
                'TN-79',
                'CT-92',
            ])
            ->get()
            ->keyBy('code');
        $allPermissions = [
            'dashboard.view',
            'sos.activate',
            'events.manage',
            'posts.manage',
            'staff.manage',
        ];

        User::query()->updateOrCreate(
            ['email' => 'system@pulselink.test'],
            [
                'name' => 'Quản trị hệ thống Pulse Link',
                'password' => Hash::make('password'),
                'role' => 'system_admin',
                'hospital_id' => null,
                'permissions' => $allPermissions,
                'province_code' => '79',
                'ward_code' => '27301',
                'latitude' => $hospital->latitude,
                'longitude' => $hospital->longitude,
                'last_seen_at' => now()->subMinutes(2),
            ],
        );

        User::query()->updateOrCreate(
            ['email' => 'admin@pulselink.test'],
            [
                'name' => 'BS Nguyễn Minh An',
                'password' => Hash::make('password'),
                'role' => 'hospital_staff',
                'hospital_id' => $hospital->id,
                'permissions' => $allPermissions,
                'province_code' => '79',
                'ward_code' => '27301',
                'latitude' => $hospital->latitude,
                'longitude' => $hospital->longitude,
                'last_seen_at' => now()->subMinutes(6),
            ],
        );

        foreach ([
            [
                'email' => 'dieuphoi@pulselink.test',
                'name' => 'ĐD Lê Thị Hồng',
                'hospital' => $bloodCenter,
                'phone' => '0902100101',
                'permissions' => ['dashboard.view', 'events.manage', 'posts.manage'],
            ],
            [
                'email' => 'sos.bachmai@pulselink.test',
                'name' => 'BS Trần Tiến Dũng',
                'hospital' => $bachMai,
                'phone' => '0902100102',
                'permissions' => ['dashboard.view', 'sos.activate'],
            ],
            [
                'email' => 'sos.vietduc@pulselink.test',
                'name' => 'BS Phạm Quốc Khánh',
                'hospital' => $staffHospitals['VD-01'],
                'phone' => '0902100103',
                'permissions' => ['dashboard.view', 'sos.activate', 'events.manage'],
            ],
            [
                'email' => 'admin.108@pulselink.test',
                'name' => 'ĐD Nguyễn Thu Trang',
                'hospital' => $staffHospitals['QD108-01'],
                'phone' => '0902100104',
                'permissions' => ['dashboard.view', 'sos.activate', 'posts.manage'],
            ],
            [
                'email' => 'sos.hue@pulselink.test',
                'name' => 'BS Hoàng Minh Châu',
                'hospital' => $staffHospitals['TWH-46'],
                'phone' => '0902100105',
                'permissions' => ['dashboard.view', 'sos.activate'],
            ],
            [
                'email' => 'admin.danang@pulselink.test',
                'name' => 'ĐD Võ Thanh Sơn',
                'hospital' => $staffHospitals['DN-48'],
                'phone' => '0902100106',
                'permissions' => ['dashboard.view', 'events.manage', 'posts.manage'],
            ],
            [
                'email' => 'admin.umc@pulselink.test',
                'name' => 'BS Lê Bảo Ngọc',
                'hospital' => $staffHospitals['UMC-79'],
                'phone' => '0902100107',
                'permissions' => ['dashboard.view', 'sos.activate', 'events.manage', 'posts.manage'],
            ],
            [
                'email' => 'sos.nhidong1@pulselink.test',
                'name' => 'ĐD Trần Mỹ Duyên',
                'hospital' => $staffHospitals['ND1-79'],
                'phone' => '0902100108',
                'permissions' => ['dashboard.view', 'sos.activate'],
            ],
            [
                'email' => 'admin.thongnhat@pulselink.test',
                'name' => 'BS Mai Anh Tuấn',
                'hospital' => $staffHospitals['TN-79'],
                'phone' => '0902100109',
                'permissions' => ['dashboard.view', 'events.manage', 'posts.manage'],
            ],
            [
                'email' => 'sos.cantho@pulselink.test',
                'name' => 'BS Cao Minh Thư',
                'hospital' => $staffHospitals['CT-92'],
                'phone' => '0902100110',
                'permissions' => ['dashboard.view', 'sos.activate', 'events.manage'],
            ],
        ] as $index => $staff) {
            User::query()->updateOrCreate(
                ['email' => $staff['email']],
                [
                    'name' => $staff['name'],
                    'password' => Hash::make('password'),
                    'phone' => $staff['phone'],
                    'role' => 'hospital_staff',
                    'hospital_id' => $staff['hospital']->id,
                    'permissions' => $staff['permissions'],
                    'province_code' => $staff['hospital']->province_code,
                    'ward_code' => $staff['hospital']->ward_code,
                    'latitude' => $staff['hospital']->latitude,
                    'longitude' => $staff['hospital']->longitude,
                    'last_seen_at' => now()->subMinutes(15 + ($index * 3)),
                ],
            );
        }

        foreach ($this->donors() as $index => $donor) {
            $user = User::query()->updateOrCreate(
                ['email' => $donor['email']],
                [
                    'name' => $donor['name'],
                    'password' => Hash::make('password'),
                    'phone' => '09'.str_pad((string) (21000000 + $index), 8, '0', STR_PAD_LEFT),
                    'role' => 'donor',
                    'blood_type' => $donor['blood_type'],
                    'hero_level' => $donor['hero_level'],
                    'badge_title' => $donor['badge_title'],
                    'total_donations' => $donor['total_donations'],
                    'points' => $donor['points'],
                    'last_donation_date' => now()->subDays($donor['days_since_donation'])->toDateString(),
                    'province_code' => $donor['province_code'],
                    'ward_code' => $donor['ward_code'],
                    'latitude' => $donor['latitude'],
                    'longitude' => $donor['longitude'],
                    'fcm_token' => $donor['fcm_token'],
                    'last_seen_at' => now()->subMinutes(($index % 45) + 1),
                ],
            );

            $total = $donor['total_donations'];
            for ($h = 1; $h <= $total; $h++) {
                $daysAgo = $donor['days_since_donation'] + ($h - 1) * 90;
                $certificateId = 'PL-2026-'.str_pad((string) $user->id, 5, '0', STR_PAD_LEFT).($h === 1 ? '' : "-{$h}");
                DonationHistory::query()->updateOrCreate(
                    ['certificate_id' => $certificateId],
                    [
                        'user_id' => $user->id,
                        'hospital_id' => $hospital->id,
                        'donated_at' => now()->subDays($daysAgo)->toDateString(),
                        'location_name' => $donor['history_location'] ?? $hospital->name,
                        'volume_ml' => $donor['blood_type'] === 'O-' ? 350 : 450,
                        'blood_type' => $donor['blood_type'],
                        'status' => 'verified',
                        'notes' => $donor['history_note'] ?? "Hồ sơ hiến máu demo lần thứ {$h} được xác minh.",
                    ],
                );
            }
        }
    }

    private function donors(): array
    {
        $base = [
            ['Trần Minh Quân', 'quan.tran@pulselink.test', 'O+', 10.7578, 106.6620, '79', '27301', 96],
            ['Nguyễn Hoài An', 'an.nguyen@pulselink.test', 'O-', 10.7612, 106.6662, '79', '27316', 122],
            ['Lê Quang Huy', 'huy.le@pulselink.test', 'A+', 10.7721, 106.6578, '79', '27226', 34],
            ['Phạm Thanh Vy', 'vy.pham@pulselink.test', 'B+', 10.7495, 106.6688, '79', '27343', 84],
            ['Đoàn Nhật Linh', 'linh.doan@pulselink.test', 'AB+', 10.7810, 106.7001, '79', '26740', 12],
            ['Võ Gia Bảo', 'bao.vo@pulselink.test', 'O+', 10.8521, 106.6297, '79', '27004', 140],
            ['Bùi Khánh Linh', 'khanhlinh.bui@pulselink.test', 'A-', 10.8040, 106.7300, '79', '26876', 91],
            ['Hoàng Đức Nam', 'nam.hoang@pulselink.test', 'B-', 10.9700, 106.6500, '79', '25747', 103],
            ['Đặng Thu Hà', 'ha.dang@pulselink.test', 'O-', 10.9574, 106.8427, '75', '25987', 87],
            ['Mai Anh Tuấn', 'tuan.mai@pulselink.test', 'O+', 11.3352, 106.1099, '80', '27628', 118],
            ['Cao Minh Thư', 'thu.cao@pulselink.test', 'AB-', 10.0306, 105.7683, '92', '31135', 100],
            ['Phan Ngọc Diệp', 'diep.phan@pulselink.test', 'A+', 16.0718, 108.2140, '48', '20275', 77],
            ['Lý Bảo Châu', 'chau.ly@pulselink.test', 'O+', 21.0008, 105.8413, '01', '00292', 89],
            ['Trịnh Gia Hân', 'han.trinh@pulselink.test', 'B+', 16.4628, 107.5908, '46', '19753', 29],
        ];

        $extraNames = [
            'Nguyễn Đức Phúc', 'Trần Mỹ Duyên', 'Lê Bảo Ngọc', 'Phạm Gia Khang', 'Hoàng Minh Châu',
            'Võ Thanh Sơn', 'Bùi Ngọc Hân', 'Đặng Quốc Việt', 'Mai Tường Vy', 'Cao Anh Kiệt',
            'Phan Như Ý', 'Lý Minh Khôi', 'Trịnh Hoàng Yến', 'Đỗ Phương Nam', 'Vũ Hải Đăng',
            'Ngô Thiên An', 'Đinh Kim Ngân', 'Huỳnh Quang Minh', 'Tạ Bảo Trân', 'Lâm Hữu Phát',
        ];
        $bloodTypes = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
        $anchors = [
            ['79', '27301', 10.7565, 106.6594],
            ['79', '27004', 10.8040, 106.6530],
            ['75', '25987', 10.9574, 106.8427],
            ['80', '27628', 11.0850, 106.2050],
            ['92', '31135', 10.0452, 105.7469],
            ['48', '20275', 16.0471, 108.2068],
            ['01', '00292', 21.0285, 105.8542],
        ];

        foreach ($extraNames as $i => $name) {
            [$province, $ward, $lat, $lng] = $anchors[$i % count($anchors)];
            $base[] = [
                $name,
                str($name)->ascii()->lower()->replace(' ', '.')->append('@pulselink.test')->toString(),
                $bloodTypes[$i % count($bloodTypes)],
                $lat + (($i % 5) - 2) * 0.018,
                $lng + (($i % 7) - 3) * 0.018,
                $province,
                $ward,
                [7, 20, 61, 83, 84, 97, 130][$i % 7],
            ];
        }

        return array_map(function (array $row, int $index): array {
            [$name, $email, $bloodType, $lat, $lng, $province, $ward, $days] = $row;
            $donations = max(1, (int) floor($days / 18) + ($index % 8));

            return [
                'name' => $name,
                'email' => $email,
                'blood_type' => $bloodType,
                'latitude' => $index === 31 ? null : $lat,
                'longitude' => $index === 31 ? null : $lng,
                'province_code' => $province,
                'ward_code' => $ward,
                'days_since_donation' => $days,
                'total_donations' => $donations,
                'points' => $donations * 250 + ($index % 5) * 80,
                'hero_level' => $donations >= 12 ? 'Platinum Badge' : ($donations >= 8 ? 'Gold Badge' : ($donations >= 4 ? 'Silver Badge' : 'Bronze Badge')),
                'badge_title' => $donations >= 12 ? 'Hiệp Sĩ Bạch Kim' : ($donations >= 8 ? 'Hiệp Sĩ Vàng' : ($donations >= 4 ? 'Hiệp Sĩ Bạc' : 'Hiệp Sĩ Đồng')),
                'fcm_token' => $index === 30 ? null : 'mock-fcm-token-'.$index,
            ];
        }, $base, array_keys($base));
    }
}
