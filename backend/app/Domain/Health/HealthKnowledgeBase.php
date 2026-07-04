<?php

namespace App\Domain\Health;

final class HealthKnowledgeBase
{
    private const KNOWLEDGE = [
        'post_donation_care' => [
            'nghi_ngoi' => 'Nằm nghỉ tại chỗ ít nhất 15-20 phút sau khi hiến máu. Không đứng dậy đột ngột để tránh chóng mặt.',
            'uong_nuoc' => 'Uống nhiều nước (từ 2-3 lít nước) trong ngày sau khi hiến máu để bù lại lượng thể tích tuần hoàn.',
            'van_dong' => 'Tránh vận động mạnh, tập thể dục nặng, khuân vác vật nặng hoặc chơi thể thao dùng nhiều sức lực trong vòng 24 giờ sau khi hiến.',
            'an_uong' => 'Duy trì chế độ ăn uống đầy đủ dinh dưỡng, giàu sắt. Không uống rượu, bia hay chất kích thích trong ngày hiến máu.',
            'cham_soc_vet_kim' => 'Giữ nguyên băng ép ở vị trí kim tiêm trong vòng 4-6 giờ. Tránh chạm nước trực tiếp vào vết kim tiêm trong thời gian này để hạn chế nhiễm trùng. Nếu có bầm tím (do thoát mạch), chườm lạnh trong 24h đầu, sau đó chườm ấm.'
        ],
        'nutrition' => [
            'thuc_pham_giau_sat' => 'Thịt bò, gan, thịt gia cầm, hải sản, các loại đậu, rau có màu xanh đậm (rau bina, cải bó xôi) là nguồn cung cấp sắt tuyệt vời.',
            'vitamin_c' => 'Ăn nhiều trái cây họ cam quýt, dâu tây, ớt chuông để bổ sung Vitamin C giúp cơ thể hấp thụ sắt tốt hơn.',
            'tranh_tra_ca_phe' => 'Hạn chế uống trà, cà phê ngay sau bữa ăn vì chất tannin và caffeine có thể ức chế sự hấp thụ chất sắt.'
        ],
        'eligibility' => [
            'can_nang' => 'Nam giới tối thiểu 45kg, Nữ giới tối thiểu 45kg.',
            'tuoi' => 'Độ tuổi quy định từ 18 đến 60 tuổi.',
            'khoang_cach' => 'Thời gian tối thiểu giữa hai lần hiến máu toàn phần là 12 tuần (khoảng 3 tháng). Với hiến tiểu cầu, khoảng cách tối thiểu là 2-3 tuần.'
        ],
        'side_effects' => [
            'nhe' => 'Chóng mặt nhẹ, mệt mỏi nhẹ hoặc bầm tím tại vị trí tiêm là những hiện tượng hoàn toàn bình thường và sẽ tự biến mất sau 1-2 ngày.',
            'nang' => 'Nếu gặp các triệu chứng như sốt cao, rét run, vị trí tiêm sưng nóng đỏ đau dữ dội, khó thở, ngất xỉu, hãy lập tức liên hệ hotline y tế hoặc đến cơ sở y tế gần nhất.'
        ]
    ];

    public static function getKnowledgeString(): string
    {
        $output = "HƯỚNG DẪN Y TẾ CHUẨN (KNOWLEDGE BASE):\n";
        foreach (self::KNOWLEDGE as $topic => $items) {
            $output .= "- Chủ đề " . strtoupper($topic) . ":\n";
            foreach ($items as $key => $value) {
                $output .= "  + " . str_replace('_', ' ', $key) . ": $value\n";
            }
        }
        return $output;
    }
}
