<?php

namespace Database\Seeders;

use App\Domain\Blood\BloodCompatibility;
use App\Domain\Emergency\DispatchWavePolicy;
use App\Models\EmergencyAlert;
use App\Models\EmergencyCommitment;
use App\Models\Hospital;
use App\Repositories\Contracts\DonorRepository;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class EmergencyScenarioSeeder extends Seeder
{
    public function __construct(
        private readonly BloodCompatibility $bloodCompatibility,
        private readonly DispatchWavePolicy $dispatchWavePolicy,
        private readonly DonorRepository $donors,
    ) {}

    public function run(): void
    {
        $this->seedAlert(
            hospitalCode: 'CR-79',
            requiredBloodType: 'O+',
            level: 'level1',
            unitsNeeded: 4,
            status: 'active',
            message: 'Báo động đỏ: cần nhóm máu O+ cho ca cấp cứu tại Bệnh viện Chợ Rẫy.',
            expiresAt: now()->addMinutes(45),
        );

        $this->seedAlert(
            hospitalCode: 'TMHH-79',
            requiredBloodType: 'A+',
            level: 'level2',
            unitsNeeded: 6,
            status: 'active',
            message: 'Cần hỗ trợ hiến máu A+ trong khu vực TP.HCM.',
            expiresAt: now()->addMinutes(80),
        );

        $this->seedAlert(
            hospitalCode: 'CR-79',
            requiredBloodType: 'O+',
            level: 'level3',
            unitsNeeded: 12,
            status: 'fulfilled',
            message: 'Kich hoat chi vien lien tinh cho nhom mau O+.',
            expiresAt: now()->subMinutes(20),
        );

        $this->seedAlert(
            hospitalCode: 'DN-48',
            requiredBloodType: 'B+',
            level: 'level3',
            unitsNeeded: 8,
            status: 'cancelled',
            message: 'Can B+ chi vien mien Trung, da huy do benh vien du mau.',
            expiresAt: now()->addMinutes(60),
        );
    }

    private function seedAlert(
        string $hospitalCode,
        string $requiredBloodType,
        string $level,
        int $unitsNeeded,
        string $status,
        string $message,
        mixed $expiresAt,
    ): EmergencyAlert {
        $hospital = Hospital::query()->where('code', $hospitalCode)->firstOrFail();
        $compatibleTypes = $this->bloodCompatibility->compatibleDonorTypesForRecipient($requiredBloodType);
        $dispatch = $this->dispatchWavePolicy->selectRecipients(
            $this->donors->compatibleActiveDonors($compatibleTypes),
            $hospital,
            $level,
        );

        $alert = EmergencyAlert::query()->updateOrCreate(
            [
                'hospital_id' => $hospital->id,
                'required_blood_type' => $requiredBloodType,
                'level' => $level,
                'message' => $message,
            ],
            [
                'public_id' => (string) Str::uuid(),
                'units_needed' => $unitsNeeded,
                'status' => $status,
                'expires_at' => $expiresAt,
                'dispatch_summary' => [
                    ...$dispatch['summary'],
                    'recipient_count' => count($dispatch['recipients']),
                ],
            ],
        );

        foreach (array_slice($dispatch['recipients'], 0, 18) as $candidate) {
            $recipient = $alert->recipients()->updateOrCreate(
                ['user_id' => $candidate->donor->id],
                [
                    'wave' => $candidate->wave,
                    'distance_km' => $candidate->distanceKm,
                    'notified_at' => now()->subMinutes(random_int(3, 30)),
                    'acknowledged_at' => $candidate->distanceKm < 30 ? now()->subMinutes(random_int(1, 12)) : null,
                ],
            );

            if ($status === 'active' && $recipient->id % 3 === 0) {
                EmergencyCommitment::query()->updateOrCreate(
                    ['emergency_alert_id' => $alert->id, 'donor_id' => $candidate->donor->id],
                    [
                        'status' => ['committed', 'en_route', 'arrived'][$recipient->id % 3],
                        'latitude' => $candidate->donor->latitude,
                        'longitude' => $candidate->donor->longitude,
                        'eta_minutes' => max(5, (int) ceil($candidate->distanceKm / 24 * 60)),
                        'committed_at' => now()->subMinutes(random_int(1, 18)),
                        'last_location_at' => now()->subMinutes(random_int(0, 5)),
                    ],
                );
            }
        }

        return $alert;
    }
}
