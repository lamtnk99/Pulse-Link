<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class BloodJourney extends Model
{
    use HasFactory;

    public const PATIENT_OPENINGS = [
        'Khi bác sĩ báo tin ca cấp cứu đang ở ranh giới mong manh nhất, cả gia đình tôi chỉ biết ôm nhau khóc.',
        'Trong căn phòng cấp cứu lạnh lẽo, nhìn nhịp tim trên máy của người thân lịm dần, chúng tôi tưởng như đã mất đi tất cả.',
        'Suốt những giờ phút căng thẳng tột cùng ngoài phòng mổ, từng giây trôi qua dài như cả thế kỷ đối với gia đình.',
        'Nhận được cuộc gọi thông báo đã tìm thấy nhóm máu tương thích, chúng tôi vỡ òa trong nước mắt vì biết người thân mình được cứu rồi.',
        'Nhìn túi máu hồng chuẩn bị được đưa vào phòng hồi sức, lòng tôi nghẹn lại vì biết ơn một người xa lạ.',
        'Giữa lúc tuyệt vọng nhất vì kho máu bệnh viện cạn kiệt, sự xuất hiện của bạn giống như một phép màu xuất hiện giữa đời thực.',
        'Không nỗi sợ hãi nào bằng việc nhìn người mình yêu thương nhất đứng trước cửa tử mà bản thân bất lực.',
        'Khi tiếng còi xe cấp cứu reo lên cũng là lúc chúng tôi nín thở chờ đợi một phép màu.',
        'Cả gia đình tôi đã có một đêm không ngủ, cầu nguyện trong sự lo âu tột độ trước phòng hồi sức cấp cứu.',
        'Giữa lằn ranh sinh tử cận kề, từng giây phút trôi qua đối với người bệnh đều là cuộc chiến khốc liệt.',
    ];

    public const PATIENT_MIDDLES = [
        'Chính những giọt máu ấm áp của bạn đã chảy vào cơ thể người thân tôi, giật lại nhịp đập sinh mệnh quý giá.',
        'Dòng máu nghĩa tình của bạn đang hòa chung dòng chảy, sưởi ấm và tiếp thêm sự sống cho một cuộc đời nguy kịch.',
        'Những giọt máu hồng trân quý ấy đã kết nối kì diệu để giữ lại một người cha, người mẹ ở lại với gia đình.',
        'Từng giọt máu nghĩa hiệp đang hồi sinh từng tế bào, mang lại cơ hội sống thứ hai cho người bệnh.',
        'Khi dòng máu của bạn chảy qua, nhịp tim trên màn hình monitor đã dần bình ổn trở lại trong niềm hạnh phúc tột cùng của chúng tôi.',
        'Sự hy sinh thầm lặng của bạn đã tiếp thêm sinh lực, giúp người thân tôi vượt qua cơn giông bão lớn nhất cuộc đời.',
        'Giọt máu hồng ấy không chỉ cứu một người, mà thực sự đã cứu vớt cả một gia đình khỏi sự đổ vỡ và đau thương.',
        'Món quà sự sống từ bạn đã giúp ca phẫu thuật kết thúc tốt đẹp và bệnh nhân đã có thể tự thở được.',
        'Chính tấm lòng nhân ái của bạn đã nâng đỡ cơ thể yếu ớt ấy vượt qua thời khắc hiểm nghèo nhất.',
        'Dòng máu lành mạnh của bạn đã hòa làm một, thắp lên hy vọng sống cho người bệnh đang nằm kia.',
    ];

    public const PATIENT_CLOSINGS = [
        'Gia đình chúng tôi xin cúi đầu cảm ơn người ân nhân xa lạ, cầu chúc bạn luôn bình an và gặp nhiều may mắn.',
        'Xin gửi tới bạn lời tri ân sâu sắc nhất từ sâu thẳm trái tim của những người vừa được tái sinh.',
        'Cảm ơn người anh hùng thầm lặng của gia đình chúng tôi, bạn là một phần sinh mệnh của người thân tôi từ hôm nay.',
        'Nghĩa cử cao đẹp này chúng tôi xin khắc cốt ghi tâm suốt đời, chúc bạn và gia đình luôn tràn ngập niềm vui.',
        'Biết ơn tấm lòng vàng của bạn khôn nguôi, cầu mong những điều tốt đẹp nhất sẽ luôn đến bên cuộc đời bạn.',
        'Cảm ơn bạn đã không ngần ngại trao đi món quà vô giá này, cuộc đời thật đẹp vì có những người như bạn.',
        'Không từ ngữ nào diễn tả hết lòng biết ơn này, xin kính chúc bạn luôn mạnh khỏe và hạnh phúc.',
        'Sự tử tế của bạn đã cứu sống một cuộc đời, gia đình chúng tôi xin gửi vạn lời chúc lành và bình an đến bạn.',
        'Xin tri ân nghĩa cử cao đẹp cứu người của bạn, cầu chúc cuộc sống của bạn luôn tràn ngập ánh sáng ấm áp.',
        'Cảm ơn bạn, người ân nhân đặc biệt đã mang nụ cười và hy vọng trở lại với mái ấm của chúng tôi.',
    ];

    public const RESERVE_OPENINGS = [
        'Bệnh viện xin gửi lời chào trân trọng và biết ơn sâu sắc nhất tới bạn.',
        'Trong ca trực đầy áp lực hôm nay, sự có mặt và hiến dâng của bạn là nguồn động viên lớn cho đội ngũ y bác sĩ.',
        'Chúng tôi vừa trải qua những giờ phút căng thẳng, và tấm lòng của bạn đã sưởi ấm cả căn phòng trực.',
        'Nhờ sự chủ động và tinh thần sẵn sàng của bạn, ca khẩn cấp đã được kiểm soát tốt trước khi kho máu cạn kiệt.',
        'Khoa Huyết học truyền máu bệnh viện vô cùng trân quý nghĩa cử cao đẹp mà bạn đã thực hiện.',
        'Sự xuất hiện kịp thời của bạn giữa lúc khẩn thiết nhất là điểm tựa vững chắc cho công tác cứu chữa bệnh nhân.',
        'Mỗi khi nhận được một đơn vị máu từ những người tình nguyện như bạn, chúng tôi lại thêm vững tin vào công việc của mình.',
        'Nhìn dòng người xếp hàng hiến máu trong tình trạng SOS, tập thể y bác sĩ vô cùng xúc động.',
        'Khi ca cấp cứu khẩn cấp cần tiếp máu khẩn thiết, hành động của bạn đã tháo gỡ khó khăn cho bệnh viện.',
        'Tập thể y bác sĩ trực cấp cứu hôm nay xin được gửi lời tri ân chân thành nhất tới tấm lòng vàng của bạn.',
    ];

    public const RESERVE_MIDDLES = [
        'Ca cấp cứu khẩn cấp hiện tại đã ổn định nhờ sự chuẩn bị chu đáo, đơn vị máu của bạn đã được kiểm tra và đưa vào lưu trữ đạt chuẩn.',
        'Máu nghĩa tình của bạn đã được tiếp nhận an toàn, lưu vào kho dự phòng để sẵn sàng làm lá chắn sinh mệnh cho các bệnh nhân nguy kịch tiếp theo.',
        'Chúng tôi đã hoàn tất quy trình sàng lọc và đưa đơn vị máu của bạn vào bảo quản nghiêm ngặt tại ngân hàng máu.',
        'Tấm lòng sẻ chia của bạn giúp ngân hàng máu luôn có sẵn nguồn tài nguyên quý giá để cấp cứu người bệnh bất kỳ lúc nào.',
        'Đơn vị máu này đã được đặt ở vị trí ưu tiên trong kho dự trữ để sẵn sàng ứng cứu cho những ca mổ khẩn cấp sắp tới.',
        'Hành động hiến máu của bạn đã trực tiếp san sẻ áp lực với ngành y tế và mang lại hy vọng sống cho cộng đồng.',
        'Sự sẻ chia của bạn là món quà vô giá, giúp chúng tôi luôn chủ động trong cuộc chiến giành giật sinh mạng người bệnh.',
        'Máu của bạn đã được bảo quản tối ưu tại kho dự trữ của bệnh viện, sẵn sàng hồi sinh những cuộc đời gặp nạn sắp tới.',
        'Nhờ có sự đóng góp của bạn, ngân hàng máu có thêm nguồn sống sẵn sàng bảo vệ những bệnh nhân ở ranh giới hiểm nghèo.',
        'Đơn vị máu hiến tặng của bạn đã được phân loại cẩn thận và lưu kho đạt chuẩn để phục vụ công tác điều trị khẩn cấp.',
    ];

    public const RESERVE_CLOSINGS = [
        'Kính chúc bạn luôn dồi dào sức khỏe, bình an và hạnh phúc trong cuộc sống.',
        'Bệnh viện xin tri ân nghĩa cử nhân ái này của bạn và mong tiếp tục được đồng hành trong những hành trình tiếp theo.',
        'Trân trọng cảm ơn bạn vì một nghĩa cử cao đẹp cứu người, chúc bạn luôn gặp nhiều điều tốt lành.',
        'Cảm ơn tấm lòng nhân ái tuyệt vời của bạn vì cộng đồng, chúc bạn luôn tràn ngập niềm vui.',
        'Xin chúc bạn và gia đình luôn an lành, hạnh phúc và gặp thật nhiều may mắn.',
        'Sự tử tế của bạn là động lực lớn lao cho chúng tôi làm việc, xin cảm ơn bạn rất nhiều.',
        'Xin chúc bạn luôn giữ mãi ngọn lửa nhân ái này trong tim để sưởi ấm thêm nhiều mảnh đời.',
        'Tri ân sâu sắc tấm lòng vàng của bạn, chúc bạn luôn bình an trên mọi nẻo đường.',
        'Cảm ơn người chiến sĩ thầm lặng trên mặt trận cứu người, kính chúc bạn mọi điều tốt đẹp nhất.',
        'Bệnh viện xin gửi vạn lời chúc lành và lời cảm ơn chân thành nhất đến bạn.',
    ];

    protected $fillable = [
        'public_id',
        'emergency_alert_id',
        'emergency_commitment_id',
        'donation_history_id',
        'donor_id',
        'hospital_id',
        'destination_type',
        'current_step',
        'location_label',
        'final_message',
        'pulse_link_message',
        'gratitude_style',
        'published_at',
        'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'published_at' => 'datetime',
            'completed_at' => 'datetime',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (BloodJourney $journey): void {
            $journey->public_id ??= (string) Str::uuid();
        });
    }

    public static function defaultSteps(string $destinationType): array
    {
        $steps = [
            ['step_key' => 'received', 'label' => 'Đã tiếp nhận'],
            ['step_key' => 'quality_check', 'label' => 'Đang kiểm tra chất lượng'],
        ];

        if ($destinationType === 'reserve') {
            $steps[] = ['step_key' => 'stored', 'label' => 'Đã lưu trữ an toàn tại kho máu bệnh viện/quốc gia'];

            return $steps;
        }

        $steps[] = ['step_key' => 'emergency_transport', 'label' => 'Đang vận chuyển cấp cứu'];
        $steps[] = ['step_key' => 'transfused', 'label' => 'Đã truyền cho bệnh nhân thành công'];

        return $steps;
    }

    public static function finalMessageFor(string $destinationType, ?int $seedId = null): string
    {
        if ($destinationType === 'reserve') {
            $openings = self::RESERVE_OPENINGS;
            $middles = self::RESERVE_MIDDLES;
            $closings = self::RESERVE_CLOSINGS;
        } else {
            $openings = self::PATIENT_OPENINGS;
            $middles = self::PATIENT_MIDDLES;
            $closings = self::PATIENT_CLOSINGS;
        }

        if ($seedId === null) {
            $seedId = rand(0, 9999);
        }

        $o = $openings[$seedId % count($openings)];
        $m = $middles[($seedId + 3) % count($middles)];
        $c = $closings[($seedId + 7) % count($closings)];

        return "$o $m $c";
    }

    public static function hasCompleteFinalMessage(?string $message): bool
    {
        $message = trim((string) $message);
        if ($message === '' || mb_strlen($message) < 80) {
            return false;
        }

        $words = preg_split('/\s+/u', $message, -1, PREG_SPLIT_NO_EMPTY) ?: [];
        if (count($words) < 18 || ! preg_match('/[.!?]$/u', $message)) {
            return false;
        }

        preg_match_all('/[.!?](?:\s|$)/u', $message, $sentences);

        return count($sentences[0]) >= 2;
    }

    public function resolvedFinalMessage(): string
    {
        return self::hasCompleteFinalMessage($this->final_message)
            ? trim($this->final_message)
            : self::finalMessageFor($this->destination_type, $this->emergency_commitment_id);
    }

    public function alert()
    {
        return $this->belongsTo(EmergencyAlert::class, 'emergency_alert_id');
    }

    public function commitment()
    {
        return $this->belongsTo(EmergencyCommitment::class, 'emergency_commitment_id');
    }

    public function donationHistory()
    {
        return $this->belongsTo(DonationHistory::class);
    }

    public function donor()
    {
        return $this->belongsTo(User::class, 'donor_id');
    }

    public function hospital()
    {
        return $this->belongsTo(Hospital::class);
    }

    public function steps()
    {
        return $this->hasMany(BloodJourneyStep::class)->orderBy('sort_order');
    }
}
