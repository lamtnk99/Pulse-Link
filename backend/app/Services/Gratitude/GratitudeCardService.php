<?php

namespace App\Services\Gratitude;

use App\Models\BloodJourney;
use App\Models\DonationHistory;

class GratitudeCardService
{
    public const STYLE_CLASSIC = 'classic';

    public const STYLE_HERO_NIGHT = 'hero_night';

    public const STYLE_BOTANICAL = 'botanical';

    public const STYLES = [
        self::STYLE_CLASSIC,
        self::STYLE_HERO_NIGHT,
        self::STYLE_BOTANICAL,
        'rose_dawn',
        'cherry_bloom',
        'sunrise_hope',
        'ocean_breeze',
        'emerald_care',
        'violet_grace',
        'golden_hour',
        'pearl_glow',
        'ruby_pulse',
        'sky_lantern',
        'mint_leaf',
        'coral_smile',
        'midnight_hero',
        'lavender_mist',
        'amber_kindness',
        'lotus_peace',
        'snow_rose',
    ];

    private const REGULAR_TEAM_MESSAGES = [
        'Cảm ơn{name} vì đã trao đi {volume} máu{blood} tại {hospital}. Món quà thầm lặng này giúp ngân hàng máu có thêm hy vọng cho những ca điều trị tiếp theo. PulseLink tự hào được đồng hành cùng bạn trên hành trình sẻ chia sự sống.',
        '{name} thân mến, {volume} máu{blood} bạn vừa hiến tại {hospital} không chỉ là một con số. Đó là sự bình tĩnh, lòng tốt và niềm hy vọng được gửi tới những người đang cần được tiếp sức.',
        'PulseLink cảm ơn{name} vì đã dành thời gian, sức khỏe và trái tim của mình cho một hành động đẹp tại {hospital}. Từng giọt máu bạn trao đi đều có thể trở thành một ngày mai bình an hơn cho ai đó.',
        'Cảm ơn{name} vì đã chọn cho đi. {volume} máu{blood} tại {hospital} là một lời nhắc dịu dàng rằng cộng đồng này vẫn luôn có những người sẵn sàng nâng đỡ nhau.',
        'Hôm nay, bạn không chỉ hoàn tất một lượt hiến máu. Bạn đã góp thêm một mạch sống vào mạng lưới yêu thương của PulseLink. Cảm ơn{name} vì {volume} máu{blood} đầy ý nghĩa.',
        'Từ đội ngũ PulseLink, xin gửi tới{name} lời cảm ơn chân thành. Nghĩa cử tại {hospital} đã giúp nguồn máu dự trữ có thêm cơ hội để kịp thời cứu người.',
        '{name} ơi, có những điều tốt đẹp không cần ồn ào. Việc bạn trao đi {volume} máu{blood} tại {hospital} là một điều như thế: lặng lẽ, tử tế và rất đáng trân trọng.',
        'Cảm ơn{name} vì đã tin rằng một hành động nhỏ cũng có thể tạo nên thay đổi lớn. PulseLink đã ghi nhận món quà sự sống của bạn tại {hospital}.',
        'Bạn vừa góp một phần sức khỏe của mình để ai đó có thêm cơ hội hồi phục. PulseLink biết ơn{name} vì {volume} máu{blood} và tinh thần sẻ chia bền bỉ.',
        'Cảm ơn{name} vì đã để lòng nhân ái trở thành hành động cụ thể. {volume} máu{blood} tại {hospital} là một món quà quý giá cho cộng đồng.',
        'Mỗi lần bạn ngồi xuống ghế hiến máu, một cơ hội sống mới lại được mở ra. PulseLink cảm ơn{name} vì đã trao đi {volume} máu{blood} bằng một trái tim thật đẹp.',
        '{hospital} đã ghi nhận lượt hiến {volume} máu{blood} của bạn. PulseLink xin cảm ơn{name} vì đã làm cho hành trình cứu người trở nên gần hơn, nhanh hơn và ấm áp hơn.',
        'Cảm ơn{name} vì đã trở thành một mắt xích tử tế trong mạng lưới hiến máu. Sự có mặt của bạn tại {hospital} hôm nay có thể là điều ai đó đang chờ đợi.',
        'PulseLink gửi{name} một lời tri ân thật nhẹ mà thật sâu: cảm ơn bạn đã cho đi khi cơ thể khỏe mạnh, để người khác có thêm sức mạnh vượt qua lúc yếu nhất.',
        'Không phải ai cũng nhìn thấy kết quả ngay lập tức, nhưng mỗi giọt máu bạn trao đi đều có đường đi của nó. Cảm ơn{name} vì {volume} máu{blood} tại {hospital}.',
        'Cảm ơn{name} vì đã biến lòng tốt thành hành động. PulseLink trân trọng từng phút bạn dành cho lượt hiến máu hôm nay.',
        '{name} thân mến, cộng đồng PulseLink có thêm một câu chuyện đẹp nhờ bạn. {volume} máu{blood} tại {hospital} là một lời hứa rằng sự sống luôn được nối tiếp.',
        'PulseLink cảm ơn{name} vì đã chọn sẻ chia thay vì đứng ngoài. Chính những nghĩa cử như bạn làm cho hệ thống hiến máu trở thành một mạng lưới của lòng tin.',
        'Cảm ơn{name} vì đã gửi đi một món quà không thể mua được bằng tiền: cơ hội sống. Đội ngũ PulseLink thật sự biết ơn bạn.',
        'Hành động hôm nay của bạn có thể sẽ được ai đó nhớ rất lâu, dù họ không biết tên bạn. PulseLink cảm ơn{name} vì đã trao đi {volume} máu{blood}.',
    ];

    private const SOS_TEAM_MESSAGES = [
        'Cảm ơn{name} vì đã đáp lại lời gọi SOS và trao đi một phần sự sống của mình tại {hospital}. Trong những phút cấp bách nhất, sự có mặt của bạn đã giúp một gia đình có thêm hy vọng. PulseLink biết ơn và tự hào khi được gọi bạn là một hiệp sĩ cứu người.',
        '{name} ơi, cảm ơn bạn vì đã không chần chừ trước một lời gọi khẩn cấp. Bạn đã biến tín hiệu SOS thành một hành động cứu người thật sự tại {hospital}.',
        'PulseLink cảm ơn{name} vì đã có mặt khi thời gian trở nên quý hơn bao giờ hết. Giọt máu{blood} bạn trao đi tại {hospital} là một mạch sống được tiếp nối.',
        'Trong khoảnh khắc nguy cấp, sự xuất hiện của bạn là điều vô cùng quý giá. Cảm ơn{name} vì đã chọn chạy về phía người cần được cứu.',
        'Bạn đã làm một điều rất lớn bằng một hành động rất thầm lặng. PulseLink tri ân{name} vì đã đáp lại ca SOS tại {hospital}.',
        'Cảm ơn{name} vì đã để lòng tốt đi nhanh hơn nỗi sợ. Sự cam kết của bạn trong ca SOS này là nguồn hy vọng thật sự.',
        'PulseLink xin cúi đầu cảm ơn{name}. Trong những phút sinh tử, bạn đã giúp hệ thống có thêm một cơ hội cứu người.',
        'Bạn không chỉ hiến máu, bạn đã trao sự bình an cho một gia đình đang chờ tin tốt. Cảm ơn{name} vì nghĩa cử tại {hospital}.',
        'Cảm ơn{name} vì đã đáp lời khi PulseLink cần bạn nhất. Sự có mặt của bạn trong ca khẩn cấp này đáng được ghi nhớ.',
        'Có những anh hùng không mặc áo choàng, chỉ âm thầm đến bệnh viện đúng lúc. PulseLink cảm ơn{name} vì đã là một người như vậy.',
        'Cảm ơn{name} vì đã trao đi {volume} máu{blood} trong một tình huống không thể chậm trễ. Bạn đã góp phần giữ lại một hy vọng sống.',
        'PulseLink biết ơn{name} vì đã tin vào lời gọi SOS và hành động ngay. Chính phản ứng nhanh của bạn làm nên giá trị của mạng lưới này.',
        'Sự tử tế của bạn đã đến đúng nơi, đúng lúc. Cảm ơn{name} vì đã trở thành điểm tựa cho {hospital} trong ca cấp cứu.',
        'Cảm ơn{name} vì đã bước vào hành trình cấp cứu bằng trái tim can đảm. Mỗi phút bạn dành ra đều rất đáng quý.',
        'PulseLink xin gửi{name} lời tri ân sâu sắc. Bạn đã không chỉ xác nhận trên ứng dụng, bạn đã thật sự có mặt cho một sự sống.',
    ];

    private const RESERVE_TEAM_MESSAGES = [
        'Cảm ơn{name} vì đã có mặt đúng lúc và gửi tặng một đơn vị máu{blood} cho {hospital}. Dù chưa đi thẳng tới một bệnh nhân cụ thể, giọt máu này đã trở thành phần dự trữ quý giá, sẵn sàng cứu người ở khoảnh khắc cần nhất.',
        'PulseLink cảm ơn{name} vì nghĩa cử bình tĩnh và đầy trách nhiệm. Đơn vị máu{blood} của bạn đang nằm trong tuyến dự phòng quý giá để sẵn sàng cứu người.',
        'Cảm ơn{name} vì đã giúp {hospital} có thêm nguồn máu an toàn trong thời điểm căng thẳng. Sự chuẩn bị hôm nay có thể là sự sống của ngày mai.',
        '{name} thân mến, máu của bạn đã trở thành một phần dự trữ quan trọng. PulseLink trân trọng sự sẵn sàng và lòng nhân ái của bạn.',
        'Dù chưa gắn với một bệnh nhân cụ thể, đóng góp của bạn vẫn vô cùng quý giá. Cảm ơn{name} vì đã giúp kho máu có thêm một cơ hội cứu người.',
        'PulseLink cảm ơn{name} vì đã trao đi khi cộng đồng cần. Một đơn vị máu dự phòng có thể là khác biệt giữa chờ đợi và kịp thời.',
        'Cảm ơn{name} vì đã để giọt máu của mình trở thành lá chắn âm thầm cho những ca cấp cứu tiếp theo tại {hospital}.',
        'Sự bình tĩnh và sẵn lòng của bạn giúp hệ thống y tế chủ động hơn trước những tình huống khẩn cấp. PulseLink biết ơn{name}.',
        'Cảm ơn{name} vì món quà dự phòng đầy nhân ái. Giọt máu{blood} này sẽ sẵn sàng lên đường khi một bệnh nhân cần đến.',
        'PulseLink trân trọng{name} vì đã góp phần giữ cho mạch sống cộng đồng không bị đứt đoạn, ngay cả trước khi tiếng gọi cấp cứu tiếp theo vang lên.',
    ];

    public function regularMessage(DonationHistory $donation, string $hospitalName): string
    {
        $donation->loadMissing('user');

        return $this->renderTemplate(
            $this->pick(self::REGULAR_TEAM_MESSAGES, $donation->certificate_id ?: 'donation-'.$donation->id),
            $this->donorName($donation->user?->name),
            $donation->volume_ml ? "{$donation->volume_ml}ml" : 'một đơn vị',
            $donation->blood_type ? " nhóm {$donation->blood_type}" : '',
            $hospitalName,
        );
    }

    public function pulseLinkMessageForJourney(BloodJourney $journey): string
    {
        $journey->loadMissing('donor', 'hospital', 'donationHistory');
        $templates = $journey->destination_type === 'reserve'
            ? self::RESERVE_TEAM_MESSAGES
            : self::SOS_TEAM_MESSAGES;

        return $this->renderTemplate(
            $this->pick($templates, $journey->public_id ?: 'journey-'.$journey->id),
            $this->donorName($journey->donor?->name),
            $journey->donationHistory?->volume_ml ? "{$journey->donationHistory->volume_ml}ml" : 'một đơn vị',
            ($journey->donationHistory?->blood_type ?: $journey->donor?->blood_type)
                ? ' nhóm '.($journey->donationHistory?->blood_type ?: $journey->donor?->blood_type)
                : '',
            $journey->hospital?->name ?: $journey->donationHistory?->location_name ?: 'bệnh viện',
        );
    }

    public function styleForDonation(DonationHistory $donation): string
    {
        return $this->styleForSeed($donation->certificate_id ?: 'donation-'.$donation->id);
    }

    public function styleForJourney(BloodJourney $journey): string
    {
        return $this->styleForSeed($journey->public_id ?: 'journey-'.$journey->id);
    }

    public function donationPayload(DonationHistory $donation, ?int $conversationId = null): array
    {
        $donation->loadMissing('user', 'hospital');

        return [
            'id' => 'donation-'.$donation->id,
            'source' => 'regular',
            'style' => $donation->gratitude_style ?: $this->styleForDonation($donation),
            'donor_name' => $donation->user?->name,
            'blood_type' => $donation->blood_type,
            'volume_ml' => $donation->volume_ml,
            'hospital_name' => $donation->hospital?->name ?: $donation->location_name,
            'donated_at' => $donation->donated_at?->toIso8601String(),
            'certificate_id' => $donation->certificate_id,
            'conversation_id' => $conversationId,
            'messages' => [
                [
                    'sender' => 'PulseLink',
                    'title' => 'Thư cảm ơn từ PulseLink',
                    'body' => $donation->gratitude_message ?: $this->regularMessage($donation, $donation->hospital?->name ?: $donation->location_name),
                    'signature' => 'Đội ngũ PulseLink',
                ],
            ],
        ];
    }

    public function sosDonationPayload(BloodJourney $journey): array
    {
        $journey->loadMissing('donor', 'hospital', 'donationHistory');
        $history = $journey->donationHistory;

        return [
            'id' => 'sos-donation-'.$journey->public_id,
            'source' => 'sos_pulselink',
            'style' => $journey->gratitude_style ?: $this->styleForJourney($journey),
            'donor_name' => $journey->donor?->name,
            'blood_type' => $history?->blood_type ?: $journey->donor?->blood_type,
            'volume_ml' => $history?->volume_ml,
            'hospital_name' => $journey->hospital?->name ?: $history?->location_name,
            'donated_at' => $history?->donated_at?->toIso8601String(),
            'certificate_id' => $history?->certificate_id,
            'blood_journey_id' => $journey->public_id,
            'destination_type' => $journey->destination_type,
            'messages' => [
                [
                    'sender' => 'PulseLink',
                    'title' => 'Một lá thư từ PulseLink',
                    'body' => $journey->pulse_link_message ?: $this->pulseLinkMessageForJourney($journey),
                    'signature' => 'Đội ngũ PulseLink',
                ],
            ],
        ];
    }

    public function journeyPayload(BloodJourney $journey): array
    {
        $journey->loadMissing('donor', 'hospital', 'donationHistory');
        $history = $journey->donationHistory;
        $isReserve = $journey->destination_type === 'reserve';

        return [
            'id' => 'journey-'.$journey->public_id,
            'source' => $isReserve ? 'sos_reserve' : 'sos_patient',
            'style' => $journey->gratitude_style ?: $this->styleForJourney($journey),
            'donor_name' => $journey->donor?->name,
            'blood_type' => $history?->blood_type ?: $journey->donor?->blood_type,
            'volume_ml' => $history?->volume_ml,
            'hospital_name' => $journey->hospital?->name ?: $history?->location_name,
            'donated_at' => $history?->donated_at?->toIso8601String(),
            'certificate_id' => $history?->certificate_id,
            'blood_journey_id' => $journey->public_id,
            'destination_type' => $journey->destination_type,
            'messages' => [
                [
                    'sender' => $isReserve ? 'Bệnh viện tiếp nhận' : 'Người nhà bệnh nhân',
                    'title' => $isReserve ? 'Lời cảm ơn từ bệnh viện' : 'Lời cảm ơn từ người nhà',
                    'body' => $journey->resolvedFinalMessage(),
                    'signature' => $isReserve ? 'Đội ngũ y tế' : 'Gia đình người nhận máu',
                ],
            ],
        ];
    }

    private function styleForSeed(string $seed): string
    {
        return $this->pick(self::STYLES, $seed);
    }

    private function pick(array $items, string $seed): string
    {
        return $items[abs(crc32($seed)) % count($items)];
    }

    private function donorName(?string $name): string
    {
        return $name ? ' '.$name : '';
    }

    private function renderTemplate(string $template, string $name, string $volume, string $blood, string $hospital): string
    {
        return strtr($template, [
            '{name}' => $name,
            '{volume}' => $volume,
            '{blood}' => $blood,
            '{hospital}' => $hospital,
        ]);
    }
}
