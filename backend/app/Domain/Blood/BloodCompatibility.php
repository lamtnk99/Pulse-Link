<?php

namespace App\Domain\Blood;

final class BloodCompatibility
{
    private const DONATION_MATRIX = [
        'O-' => ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'],
        'O+' => ['O+', 'A+', 'B+', 'AB+'],
        'A-' => ['A-', 'A+', 'AB-', 'AB+'],
        'A+' => ['A+', 'AB+'],
        'B-' => ['B-', 'B+', 'AB-', 'AB+'],
        'B+' => ['B+', 'AB+'],
        'AB-' => ['AB-', 'AB+'],
        'AB+' => ['AB+'],
    ];

    public function compatibleDonorTypesForRecipient(string $recipientBloodType): array
    {
        return array_values(array_filter(
            array_keys(self::DONATION_MATRIX),
            fn (string $donorType): bool => in_array($recipientBloodType, self::DONATION_MATRIX[$donorType], true)
        ));
    }

    public function canDonateTo(string $donorBloodType, string $recipientBloodType): bool
    {
        return in_array($recipientBloodType, self::DONATION_MATRIX[$donorBloodType] ?? [], true);
    }
}
