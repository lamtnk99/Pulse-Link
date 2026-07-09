<?php

namespace App\Services\Gratitude;

use App\Models\BloodJourney;
use App\Models\DonationHistory;

class GratitudeCardService
{
    public const STYLE_CLASSIC = 'classic';
    public const STYLE_HERO_NIGHT = 'hero_night';
    public const STYLE_BOTANICAL = 'botanical';

    public function regularMessage(DonationHistory $donation, string $hospitalName): string
    {
        $name = $donation->user?->name ? ' '.$donation->user->name : '';
        $volume = $donation->volume_ml ? "{$donation->volume_ml}ml" : 'một đơn vị';
        $bloodType = $donation->blood_type ? " nhóm {$donation->blood_type}" : '';

        return "Cảm ơn{$name} vì đã trao đi {$volume} máu{$bloodType} tại {$hospitalName}. "
            .'Món quà thầm lặng này giúp ngân hàng máu có thêm hy vọng cho những ca điều trị tiếp theo. '
            .'PulseLink tự hào được đồng hành cùng bạn trên hành trình sẻ chia sự sống.';
    }

    public function pulseLinkMessageForJourney(BloodJourney $journey): string
    {
        $journey->loadMissing('donor', 'hospital', 'donationHistory');
        $name = $journey->donor?->name ? ' '.$journey->donor->name : '';
        $hospital = $journey->hospital?->name ?: $journey->donationHistory?->location_name ?: 'bệnh viện';
        $bloodType = $journey->donationHistory?->blood_type ?: $journey->donor?->blood_type;
        $bloodLine = $bloodType ? " nhóm {$bloodType}" : '';

        if ($journey->destination_type === 'reserve') {
            return "Cảm ơn{$name} vì đã có mặt đúng lúc và gửi tặng một đơn vị máu{$bloodLine} cho {$hospital}. "
                .'Dù chưa đi thẳng tới một bệnh nhân cụ thể, giọt máu này đã trở thành phần dự trữ quý giá, sẵn sàng cứu người ở khoảnh khắc cần nhất. '
                .'PulseLink trân trọng nghĩa cử bình tĩnh, tử tế và đầy trách nhiệm của bạn.';
        }

        return "Cảm ơn{$name} vì đã đáp lại lời gọi SOS và trao đi một phần sự sống của mình tại {$hospital}. "
            .'Trong những phút cấp bách nhất, sự có mặt của bạn đã giúp một gia đình có thêm hy vọng. '
            .'PulseLink biết ơn và tự hào khi được gọi bạn là một hiệp sĩ cứu người.';
    }

    public function donationPayload(DonationHistory $donation, ?int $conversationId = null): array
    {
        $donation->loadMissing('user', 'hospital');

        return [
            'id' => 'donation-'.$donation->id,
            'source' => 'regular',
            'style' => $donation->gratitude_style ?: self::STYLE_CLASSIC,
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
                    'signature' => 'PulseLink Team',
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
            'style' => self::STYLE_HERO_NIGHT,
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
            'style' => $journey->gratitude_style ?: ($isReserve ? self::STYLE_BOTANICAL : self::STYLE_HERO_NIGHT),
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
                    'body' => $journey->final_message ?: BloodJourney::finalMessageFor($journey->destination_type, $journey->emergency_commitment_id),
                    'signature' => $isReserve ? 'Đội ngũ y tế' : 'Gia đình người nhận máu',
                ],
            ],
        ];
    }
}
