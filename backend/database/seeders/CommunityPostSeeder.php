<?php

namespace Database\Seeders;

use App\Models\CommunityPost;
use App\Models\Hospital;
use App\Models\User;
use Illuminate\Database\Seeder;

class CommunityPostSeeder extends Seeder
{
    public function run(): void
    {
        $choRay = Hospital::query()->where('code', 'CR-79')->firstOrFail();
        $bloodCenter = Hospital::query()->where('code', 'TMHH-79')->firstOrFail();
        $bachMai = Hospital::query()->where('code', 'BM-01')->firstOrFail();
        $admin = User::query()
            ->whereIn('role', ['hospital_staff', 'system_admin'])
            ->orderByRaw("case when email = 'admin@pulselink.test' then 0 else 1 end")
            ->first();

        $posts = [
            [
                'hospital_id' => $choRay->id,
                'author_id' => $admin?->id,
                'title' => 'Hiến máu sau 3 tháng: vì sao cơ thể cần thời gian hồi phục?',
                'slug' => 'hien-mau-sau-3-thang-vi-sao-co-the-can-thoi-gian-hoi-phuc',
                'excerpt' => 'Khoảng nghỉ 12 tuần giúp cơ thể tái tạo hồng cầu, ổn định thể lực và chuẩn bị tốt cho lần hiến tiếp theo.',
                'content' => "Sau mỗi lần hiến máu, cơ thể cần thời gian để bù lại lượng hồng cầu đã trao đi. Với người trưởng thành khỏe mạnh, mốc 3 tháng là khoảng thời gian an toàn thường được khuyến nghị trước lần hiến tiếp theo.\n\nTrong giai đoạn này, bạn nên uống đủ nước, ngủ đủ giấc, bổ sung thực phẩm giàu sắt như thịt đỏ, trứng, rau xanh đậm và tái khám nếu thấy mệt kéo dài. Pulse Link sẽ tự động nhắc ngày đủ điều kiện để bạn không cần tự ghi nhớ.",
                'image_url' => 'https://images.unsplash.com/photo-1530026405186-ed1f139313f8?auto=format&fit=crop&q=80&w=900',
                'status' => 'published',
                'published_at' => now()->subDays(1),
                'audience_type' => 'all',
                'province_code' => '79',
                'ward_code' => '27301',
                'views_count' => 1840,
                'shares_count' => 126,
            ],
            [
                'hospital_id' => $bloodCenter->id,
                'author_id' => $admin?->id,
                'title' => 'TP.HCM cần thêm người hiến nhóm máu O+ trong tuần này',
                'slug' => 'tp-hcm-can-them-nguoi-hien-nhom-mau-o-trong-tuan-nay',
                'excerpt' => 'Các điểm hiến máu thường quy tại TP.HCM đang ưu tiên nhóm O+ để bổ sung nguồn dự trữ an toàn.',
                'content' => "Nhóm máu O+ thường được sử dụng trong nhiều tình huống điều trị nên nhu cầu dự trữ luôn cao. Tuần này, các bệnh viện trong mạng lưới Pulse Link tại TP.HCM mở thêm nhiều điểm tiếp nhận để người dân thuận tiện đăng ký.\n\nNếu bạn đủ điều kiện sức khỏe, hãy chọn một sự kiện gần mình trong ứng dụng. Mỗi lượt đặt lịch giúp bệnh viện dự đoán tốt hơn lượng máu tiếp nhận trong ngày.",
                'image_url' => 'https://images.unsplash.com/photo-1615461066841-6116e61058f4?auto=format&fit=crop&q=80&w=900',
                'status' => 'published',
                'published_at' => now()->subHours(10),
                'audience_type' => 'blood_type',
                'target_blood_type' => 'O+',
                'province_code' => '79',
                'ward_code' => '27238',
                'views_count' => 950,
                'shares_count' => 88,
            ],
            [
                'hospital_id' => $bachMai->id,
                'author_id' => $admin?->id,
                'title' => 'Một lần giữ lời hẹn, nhiều ca bệnh có thêm cơ hội',
                'slug' => 'mot-lan-giu-loi-hen-nhieu-ca-benh-co-them-co-hoi',
                'excerpt' => 'Câu chuyện từ các tình nguyện viên duy trì lịch hiến đều đặn và cách họ chuẩn bị trước ngày hiến máu.',
                'content' => "Điều quý nhất trong một lịch hiến máu không chỉ là lượng máu được tiếp nhận, mà còn là sự đúng hẹn. Khi bạn xác nhận tham gia, ekip y tế có thể chuẩn bị vật tư, nhân sự và phân luồng tiếp nhận phù hợp hơn.\n\nTrước ngày hiến máu, hãy ăn nhẹ, tránh rượu bia, ngủ đủ và mang giấy tờ tùy thân. Sau khi hiến, bạn nên nghỉ tại điểm tiếp nhận ít nhất 10 phút và theo dõi phản ứng cơ thể.",
                'image_url' => 'https://images.unsplash.com/photo-1579154204601-01588f351167?auto=format&fit=crop&q=80&w=900',
                'status' => 'published',
                'published_at' => now()->subDays(3),
                'audience_type' => 'all',
                'province_code' => '01',
                'ward_code' => '00292',
                'views_count' => 1320,
                'shares_count' => 204,
            ],
            [
                'hospital_id' => $choRay->id,
                'author_id' => $admin?->id,
                'title' => 'Bản nháp: hướng dẫn cập nhật Hero Pass tại quầy tiếp nhận',
                'slug' => 'ban-nhap-huong-dan-cap-nhat-hero-pass-tai-quay-tiep-nhan',
                'excerpt' => 'Bài viết nháp để đội truyền thông bệnh viện hoàn thiện trước khi xuất bản.',
                'content' => 'Nội dung nháp dành cho quản trị viên Pulse Link.',
                'image_url' => 'https://images.unsplash.com/photo-1584516150909-c43483ee7932?auto=format&fit=crop&q=80&w=900',
                'status' => 'draft',
                'published_at' => null,
                'audience_type' => 'province',
                'province_code' => '79',
                'ward_code' => '27301',
                'views_count' => 0,
                'shares_count' => 0,
            ],
        ];

        foreach ($posts as $post) {
            CommunityPost::query()->updateOrCreate(
                ['slug' => $post['slug']],
                $post,
            );
        }
    }
}
