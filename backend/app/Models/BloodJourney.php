<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class BloodJourney extends Model
{
    use HasFactory;

    public const PATIENT_FINAL_MESSAGE = 'Giọt máu quý giá của bạn đã được truyền cho bệnh nhân tại phòng cấp cứu. Cảm ơn bạn đã giành lại một mạng sống!';

    public const RESERVE_FINAL_MESSAGE = 'Ca cấp cứu hiện đã ổn định nhờ sự hỗ trợ kịp thời. Đơn vị máu của bạn đã được lưu trữ an toàn tại kho máu dự trữ để sẵn sàng cứu sống những bệnh nhân tiếp theo. Cảm ơn nghĩa cử cao đẹp của bạn!';

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

    public static function finalMessageFor(string $destinationType): string
    {
        return $destinationType === 'reserve'
            ? self::RESERVE_FINAL_MESSAGE
            : self::PATIENT_FINAL_MESSAGE;
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
