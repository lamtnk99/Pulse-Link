<?php

namespace Database\Seeders;

use App\Models\DonationCampaign;
use App\Models\CampaignDonation;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class DonationCampaignSeeder extends Seeder
{
    public function run(): void
    {
        // Fetch donors
        $quan = User::query()->where('email', 'quan.tran@pulselink.test')->first();
        $an = User::query()->where('email', 'an.nguyen@pulselink.test')->first();
        $huy = User::query()->where('email', 'huy.le@pulselink.test')->first();
        $vy = User::query()->where('email', 'vy.pham@pulselink.test')->first();

        // 1. Financial Campaign
        $campaign1 = DonationCampaign::create([
            'public_id' => (string) Str::uuid(),
            'title' => 'Quỹ Hỗ Trợ Viện Phí Ca SOS Hoàn Cảnh Khó Khăn',
            'description' => 'Hỗ trợ chi phí điều trị khẩn cấp và truyền máu cho các bệnh nhi nghèo đang điều trị tại Khoa Cấp cứu Bệnh viện Nhi Đồng 1. Mỗi đóng góp của bạn là niềm hy vọng sống cho các em.',
            'image_url' => 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=800&auto=format&fit=crop&q=60',
            'type' => 'financial',
            'target_amount' => 80000000.00,
            'current_amount' => 0.00,
            'status' => 'active',
            'beneficiary_name' => 'Bé Gia Bảo, 6 tuổi',
            'beneficiary_story' => 'Gia Bảo mắc bệnh tan máu bẩm sinh (Thalassemia), mỗi tháng em cần truyền máu và thải sắt để duy trì sự sống. Ba em làm phụ hồ, mẹ bán vé số, khoản viện phí hơn 8 triệu mỗi đợt vượt xa thu nhập của gia đình. "Con chỉ mong được đi học lại với các bạn" - Gia Bảo nói khi nằm trên giường bệnh. Mỗi phần đóng góp của bạn giúp em có thêm một lần truyền máu an toàn.',
            'impact_unit' => 'ngày điều trị',
            'impact_per_unit_amount' => 250000,
            'urgency_level' => 'critical',
            'expires_at' => now()->addDays(30),
        ]);

        $donations1 = [
            ['user' => $quan, 'amount' => 5000000, 'name' => 'Trần Minh Quân', 'msg' => 'Chúc bé mau chóng bình phục!', 'anon' => false],
            ['user' => $an, 'amount' => 2000000, 'name' => 'Nguyễn Hoài An', 'msg' => 'Chung tay vì nụ cười trẻ thơ.', 'anon' => false],
            ['user' => null, 'amount' => 10000000, 'name' => 'Hiệp sĩ ẩn danh', 'msg' => 'Mong ca mổ thành công.', 'anon' => true],
            ['user' => $huy, 'amount' => 1500000, 'name' => 'Lê Quang Huy', 'msg' => 'Hi vọng em sớm được về nhà.', 'anon' => false],
        ];

        foreach ($donations1 as $d) {
            CampaignDonation::create([
                'donation_campaign_id' => $campaign1->id,
                'user_id' => $d['user']?->id,
                'amount' => $d['amount'],
                'points' => 0,
                'payment_method' => 'momo',
                'payment_status' => 'success',
                'transaction_id' => 'TXN-' . strtoupper(Str::random(12)),
                'donor_name' => $d['name'],
                'message' => $d['msg'],
                'is_anonymous' => $d['anon'],
                'created_at' => now()->subDays(rand(1, 4)),
            ]);
            $campaign1->increment('current_amount', $d['amount']);
        }

        // 2. Points Campaign
        $campaign2 = DonationCampaign::create([
            'public_id' => (string) Str::uuid(),
            'title' => 'Góp Điểm Hero - Đổi Thiết Bị Y Tế Bản Cao',
            'description' => 'Pulse Link quy đổi số điểm Hero của bạn thành các tủ thuốc y tế bản làng, cặp phao cứu sinh và thiết bị sơ cứu gửi tới học sinh vùng biên giới Hà Giang trong mùa lũ.',
            'image_url' => 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=800&auto=format&fit=crop&q=60',
            'type' => 'points',
            'target_points' => 10000,
            'current_points' => 0,
            'status' => 'active',
            'beneficiary_name' => 'Điểm trường Lũng Cú, Hà Giang',
            'beneficiary_story' => 'Điểm trường Lũng Cú có 42 em nhỏ, cách trạm y tế gần nhất hơn 15km đường núi. Mùa lũ về, một vết thương nhỏ cũng có thể trở thành nguy hiểm khi không có bông băng, thuốc sát trùng. Thầy cô ở đây vẫn tự bỏ tiền túi mua thuốc dự phòng cho các em. Điểm Hero bạn tích lũy từ những lần hiến máu nay có thể hóa thành một tủ thuốc thật, đặt ngay tại lớp học của các em.',
            'impact_unit' => 'bộ sơ cứu',
            'impact_per_unit_points' => 200,
            'urgency_level' => 'normal',
            'expires_at' => now()->addDays(45),
        ]);

        $donations2 = [
            ['user' => $quan, 'pts' => 500, 'name' => 'Trần Minh Quân', 'msg' => 'Gửi chút hơi ấm tới vùng cao.', 'anon' => false],
            ['user' => $an, 'pts' => 800, 'name' => 'Nguyễn Hoài An', 'msg' => 'Quyên góp điểm tích lũy của tôi.', 'anon' => false],
            ['user' => $vy, 'pts' => 1500, 'name' => 'Phạm Thanh Vy', 'msg' => 'Rất mong có thêm nhiều tủ thuốc cho bản.', 'anon' => false],
            ['user' => $huy, 'pts' => 300, 'name' => 'Lê Quang Huy', 'msg' => 'Lan tỏa yêu thương.', 'anon' => false],
        ];

        foreach ($donations2 as $d) {
            CampaignDonation::create([
                'donation_campaign_id' => $campaign2->id,
                'user_id' => $d['user']?->id,
                'amount' => 0,
                'points' => $d['pts'],
                'payment_method' => 'points',
                'payment_status' => 'success',
                'transaction_id' => 'PTS-' . strtoupper(Str::random(12)),
                'donor_name' => $d['name'],
                'message' => $d['msg'],
                'is_anonymous' => $d['anon'],
                'created_at' => now()->subDays(rand(1, 8)),
            ]);
            $campaign2->increment('current_points', $d['pts']);
        }

        // 3. Mixed Both Campaign
        $campaign3 = DonationCampaign::create([
            'public_id' => (string) Str::uuid(),
            'title' => 'Chung Tay Chiến Dịch Hành Trình Đỏ 2026',
            'description' => 'Hành trình đỏ kết nối dòng máu Việt đi qua 40 tỉnh thành. Quỹ tiếp nhận cả đóng góp tài chính (tổ chức ngày hội hiến máu) và điểm Hero (chuẩn bị suất ăn bồi dưỡng cho người hiến máu).',
            'image_url' => 'https://images.unsplash.com/photo-1505155485765-d06de4859332?w=800&auto=format&fit=crop&q=60',
            'type' => 'both',
            'target_amount' => 50000000.00,
            'current_amount' => 0.00,
            'target_points' => 5000,
            'current_points' => 0,
            'status' => 'active',
            'beneficiary_name' => 'Ngân hàng máu toàn quốc',
            'beneficiary_story' => 'Mỗi mùa hè, lượng máu dự trữ tại các bệnh viện lại chạm đáy khi sinh viên - nguồn hiến máu chính - về quê nghỉ hè. Hành Trình Đỏ đi qua 40 tỉnh thành để giữ cho dòng máu cứu người không bao giờ cạn. Đóng góp tài chính giúp tổ chức một ngày hội hiến máu; điểm Hero của bạn thành suất ăn ấm nóng tiếp sức cho những người vừa rời ghế hiến máu. Mỗi giọt máu kịp thời là một gia đình được giữ lại người thân.',
            'impact_unit' => 'suất ăn tiếp sức',
            'impact_per_unit_amount' => 35000,
            'impact_per_unit_points' => 50,
            'urgency_level' => 'urgent',
            'expires_at' => now()->addDays(20),
        ]);

        // Cash donations for Campaign 3
        $donations3_cash = [
            ['user' => $an, 'amount' => 3000000, 'name' => 'Nguyễn Hoài An', 'msg' => 'Đồng hành cùng Hành trình Đỏ.', 'anon' => false],
            ['user' => null, 'amount' => 5000000, 'name' => 'Ẩn danh', 'msg' => 'Chúc ngày hội hiến máu thành công rực rỡ.', 'anon' => true],
        ];

        foreach ($donations3_cash as $d) {
            CampaignDonation::create([
                'donation_campaign_id' => $campaign3->id,
                'user_id' => $d['user']?->id,
                'amount' => $d['amount'],
                'points' => 0,
                'payment_method' => 'vnpay',
                'payment_status' => 'success',
                'transaction_id' => 'TXN-' . strtoupper(Str::random(12)),
                'donor_name' => $d['name'],
                'message' => $d['msg'],
                'is_anonymous' => $d['anon'],
                'created_at' => now()->subDays(rand(1, 3)),
            ]);
            $campaign3->increment('current_amount', $d['amount']);
        }

        // Points donations for Campaign 3
        $donations3_pts = [
            ['user' => $quan, 'pts' => 200, 'name' => 'Trần Minh Quân', 'msg' => 'Ủng hộ sữa và suất ăn.', 'anon' => false],
            ['user' => $vy, 'pts' => 500, 'name' => 'Phạm Thanh Vy', 'msg' => 'Góp phần bồi dưỡng người hiến máu.', 'anon' => false],
        ];

        foreach ($donations3_pts as $d) {
            CampaignDonation::create([
                'donation_campaign_id' => $campaign3->id,
                'user_id' => $d['user']?->id,
                'amount' => 0,
                'points' => $d['pts'],
                'payment_method' => 'points',
                'payment_status' => 'success',
                'transaction_id' => 'PTS-' . strtoupper(Str::random(12)),
                'donor_name' => $d['name'],
                'message' => $d['msg'],
                'is_anonymous' => $d['anon'],
                'created_at' => now()->subDays(rand(1, 3)),
            ]);
            $campaign3->increment('current_points', $d['pts']);
        }
    }
}
