<?php

namespace Database\Seeders;

use App\Models\DonationAppointment;
use App\Models\DonationEvent;
use App\Models\Hospital;
use App\Models\User;
use Illuminate\Database\Seeder;

class DailyScenarioSeeder extends Seeder
{
    public function run(): void
    {
        $choRay = Hospital::query()->where('code', 'CR-79')->firstOrFail();
        $bachMai = Hospital::query()->where('code', 'BM-01')->firstOrFail();
        $daNang = Hospital::query()->where('code', 'DN-48')->firstOrFail();
        $canTho = Hospital::query()->where('code', 'CT-92')->firstOrFail();

        $events = [
            [
                'hospital_id' => $choRay->id,
                'title' => 'Chủ Nhật Đỏ - Đại học Bách Khoa TP.HCM',
                'organizer' => 'Hội Chữ thập đỏ TP.HCM',
                'description' => 'Điểm hiến máu lưu động dành cho sinh viên, giảng viên và cư dân khu vực Quận 10. Người tham gia nên ăn nhẹ, uống đủ nước và mang giấy tờ tùy thân.',
                'starts_at' => now()->addDays(5)->setTime(7, 30),
                'ends_at' => now()->addDays(5)->setTime(11, 30),
                'location_name' => 'Sân đại sảnh B6, Đại học Bách Khoa TP.HCM',
                'province_code' => '79',
                'ward_code' => '27226',
                'latitude' => 10.7721,
                'longitude' => 106.6578,
                'urgency' => 'high',
                'capacity' => 220,
                'booked_count' => 0,
            ],
            [
                'hospital_id' => $choRay->id,
                'title' => 'Giọt Hồng Nhân Ái - Công viên phần mềm Quang Trung',
                'organizer' => 'Trung tâm Hiến máu Nhân đạo TP.HCM',
                'description' => 'Ngày hội hiến máu thường quy cho khối văn phòng và cư dân phía Tây Bắc thành phố, có khu vực nghỉ sau hiến và tư vấn sức khỏe tại chỗ.',
                'starts_at' => now()->addDays(9)->setTime(8, 0),
                'ends_at' => now()->addDays(9)->setTime(16, 0),
                'location_name' => 'Công viên phần mềm Quang Trung, TP.HCM',
                'province_code' => '79',
                'ward_code' => '27004',
                'latitude' => 10.8521,
                'longitude' => 106.6297,
                'urgency' => 'normal',
                'capacity' => 180,
                'booked_count' => 0,
            ],
            [
                'hospital_id' => $bachMai->id,
                'title' => 'Ngày hội Hiến máu - Bạch Mai',
                'organizer' => 'Viện Huyết học Truyền máu Trung ương',
                'description' => 'Chương trình tiếp nhận máu tập trung tại Hà Nội, ưu tiên người đã có lịch hẹn để rút ngắn thời gian chờ và bảo đảm phân luồng an toàn.',
                'starts_at' => now()->addDays(11)->setTime(7, 0),
                'ends_at' => now()->addDays(11)->setTime(15, 30),
                'location_name' => '78 Giải Phóng, Hà Nội',
                'province_code' => '01',
                'ward_code' => '00292',
                'latitude' => 21.0008,
                'longitude' => 105.8413,
                'urgency' => 'high',
                'capacity' => 260,
                'booked_count' => 0,
            ],
            [
                'hospital_id' => $daNang->id,
                'title' => 'Trao Giọt Máu Đào - Đà Nẵng',
                'organizer' => 'Thành đoàn Đà Nẵng',
                'description' => 'Sự kiện cộng đồng tại trung tâm thành phố Đà Nẵng, phù hợp cho người hiến nhắc lại và tình nguyện viên mới đăng ký lần đầu.',
                'starts_at' => now()->addDays(14)->setTime(8, 0),
                'ends_at' => now()->addDays(14)->setTime(12, 0),
                'location_name' => '124 Hải Phòng, Đà Nẵng',
                'province_code' => '48',
                'ward_code' => '20275',
                'latitude' => 16.0718,
                'longitude' => 108.2140,
                'urgency' => 'normal',
                'capacity' => 150,
                'booked_count' => 0,
            ],
            [
                'hospital_id' => $canTho->id,
                'title' => 'Sắc Đỏ Tây Đô - Cần Thơ',
                'organizer' => 'Hội Chữ thập đỏ Cần Thơ',
                'description' => 'Điểm hiến máu cuối tuần tại Cần Thơ, hỗ trợ người dân đặt lịch trước và nhận nhắc lịch qua ứng dụng Pulse Link.',
                'starts_at' => now()->addDays(18)->setTime(7, 30),
                'ends_at' => now()->addDays(18)->setTime(13, 0),
                'location_name' => '315 Nguyễn Văn Linh, Cần Thơ',
                'province_code' => '92',
                'ward_code' => '31135',
                'latitude' => 10.0306,
                'longitude' => 105.7683,
                'urgency' => 'normal',
                'capacity' => 170,
                'booked_count' => 0,
            ],
        ];

        foreach ($events as $event) {
            DonationEvent::query()->updateOrCreate(
                ['title' => $event['title']],
                [
                    ...$event,
                    'image_url' => 'https://images.unsplash.com/photo-1615461066841-6116e61058f4?auto=format&fit=crop&q=80&w=600',
                    'is_published' => true,
                ],
            );
        }

        $donors = User::query()->where('role', 'donor')->orderBy('id')->limit(16)->get();
        $events = DonationEvent::query()->orderBy('starts_at')->get();

        foreach ($donors as $index => $donor) {
            $event = $events[$index % $events->count()];
            DonationAppointment::query()->updateOrCreate(
                ['donation_event_id' => $event->id, 'user_id' => $donor->id],
                [
                    'status' => ['booked', 'checked_in', 'completed', 'cancelled', 'deferred', 'no_show'][$index % 6],
                    'booked_at' => now()->subDays($index % 5),
                    'checked_in_at' => in_array($index % 6, [1, 2, 4], true) ? now()->subHours(2) : null,
                    'completed_at' => $index % 6 === 2 ? now()->subHour() : null,
                    'cancelled_at' => $index % 6 === 3 ? now()->subHour() : null,
                    'no_show_at' => $index % 6 === 5 ? now()->subMinutes(45) : null,
                    'volume_ml' => $index % 6 === 2 ? [250, 350, 450][$index % 3] : null,
                    'screening_status' => $index % 6 === 4 ? 'ineligible' : ($index % 6 === 2 ? 'eligible' : null),
                    'screening_notes' => $index % 6 === 4 ? 'Tạm hoãn sau khám sàng lọc tại điểm hiến.' : null,
                    'result_summary' => $index % 6 === 2 ? 'Kết quả sàng lọc đã ghi nhận, người hiến đủ điều kiện.' : null,
                    'result_published_at' => $index % 6 === 2 ? now()->subMinutes(20) : null,
                ],
            );
        }

        $defaultDonor = User::query()->where('role', 'donor')->orderBy('id')->first();
        $firstEvent = $events->first();
        if ($defaultDonor && $firstEvent) {
            DonationAppointment::query()->updateOrCreate(
                ['donation_event_id' => $firstEvent->id, 'user_id' => $defaultDonor->id],
                ['status' => 'booked', 'booked_at' => now()->subHours(6)],
            );
        }

        foreach ($events as $event) {
            $event->refreshBookedCount();
        }
    }
}
