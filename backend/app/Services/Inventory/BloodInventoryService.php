<?php

namespace App\Services\Inventory;

use App\Models\BloodSafetyThreshold;
use App\Models\BloodStock;
use App\Models\BloodStockMovement;
use App\Models\DonationHistory;
use App\Models\SmartAlert;
use Illuminate\Support\Carbon;
use Illuminate\Validation\ValidationException;

class BloodInventoryService
{
    public const STATUS_PROCESSING = 'processing';
    public const STATUS_AVAILABLE = 'available';
    public const STATUS_ALLOCATED = 'allocated';
    public const STATUS_USED = 'used';
    public const STATUS_EXPIRED = 'expired';
    public const STATUS_DISCARDED = 'discarded';

    /**
     * Ghi nhận đơn vị máu sau hiến. Bản ghi được bảo vệ bằng khóa duy nhất
     * donation_history_id để thao tác retry không thể cộng kho hai lần.
     */
    public function receiveDonation(
        DonationHistory $history,
        int $hospitalId,
        string $initialStatus,
        string $movementType,
        string $sourceType,
        int $sourceId,
        ?int $actorId = null,
        ?string $notes = null,
    ): BloodStock {
        $stock = BloodStock::query()
            ->where('donation_history_id', $history->id)
            ->lockForUpdate()
            ->first();

        if ($stock) {
            return $stock;
        }

        $availableDelta = $initialStatus === self::STATUS_AVAILABLE ? 1 : 0;
        $stock = BloodStock::query()->create([
            'hospital_id' => $hospitalId,
            'blood_type' => $history->blood_type,
            'volume_ml' => $history->volume_ml,
            'received_date' => Carbon::parse($history->donated_at)->toDateString(),
            'expiry_date' => Carbon::parse($history->donated_at)->addDays(35)->toDateString(),
            'status' => $initialStatus,
            'donation_history_id' => $history->id,
            'notes' => $notes,
        ]);

        $this->recordMovement(
            stock: $stock,
            movementType: $movementType,
            fromStatus: null,
            toStatus: $initialStatus,
            availableDelta: $availableDelta,
            sourceType: $sourceType,
            sourceId: $sourceId,
            actorId: $actorId,
            notes: $notes,
            idempotencyKey: "{$sourceType}:{$sourceId}:received",
        );

        if ($availableDelta !== 0) {
            $this->reconcileScarcityAlert($stock->hospital_id, $stock->blood_type);
        }

        return $stock;
    }

    public function addManualStock(
        int $hospitalId,
        string $bloodType,
        int $volumeMl,
        string $receivedDate,
        string $expiryDate,
        ?int $actorId = null,
        ?string $notes = null,
    ): BloodStock {
        $stock = BloodStock::query()->create([
            'hospital_id' => $hospitalId,
            'blood_type' => $bloodType,
            'volume_ml' => $volumeMl,
            'received_date' => $receivedDate,
            'expiry_date' => $expiryDate,
            'status' => self::STATUS_AVAILABLE,
            'notes' => $notes,
        ]);

        $this->recordMovement(
            stock: $stock,
            movementType: 'manual_stock_received',
            fromStatus: null,
            toStatus: self::STATUS_AVAILABLE,
            availableDelta: 1,
            sourceType: 'blood_stock',
            sourceId: $stock->id,
            actorId: $actorId,
            notes: $notes,
            idempotencyKey: "blood_stock:{$stock->id}:received",
        );
        $this->reconcileScarcityAlert($hospitalId, $bloodType);

        return $stock;
    }

    public function transition(
        BloodStock $stock,
        string $toStatus,
        string $movementType,
        string $sourceType,
        int $sourceId,
        ?int $actorId = null,
        ?string $notes = null,
        ?string $idempotencySuffix = null,
    ): BloodStock {
        $stock = BloodStock::query()->lockForUpdate()->findOrFail($stock->id);
        $fromStatus = $stock->status;

        if ($fromStatus === $toStatus) {
            return $stock;
        }

        $this->assertAllowedTransition($fromStatus, $toStatus);
        $availableDelta = $this->availableDelta($fromStatus, $toStatus);

        $stock->update([
            'status' => $toStatus,
            'notes' => $notes ?? $stock->notes,
        ]);

        $suffix = $idempotencySuffix ?? "{$fromStatus}:{$toStatus}";
        $this->recordMovement(
            stock: $stock,
            movementType: $movementType,
            fromStatus: $fromStatus,
            toStatus: $toStatus,
            availableDelta: $availableDelta,
            sourceType: $sourceType,
            sourceId: $sourceId,
            actorId: $actorId,
            notes: $notes,
            idempotencyKey: "{$sourceType}:{$sourceId}:{$suffix}",
        );

        if ($availableDelta !== 0) {
            $this->reconcileScarcityAlert($stock->hospital_id, $stock->blood_type);
        }

        return $stock->refresh();
    }

    public function reconcileScarcityAlert(int $hospitalId, string $bloodType): void
    {
        $threshold = BloodSafetyThreshold::query()
            ->where('hospital_id', $hospitalId)
            ->where('blood_type', $bloodType)
            ->first();

        if (! $threshold) {
            return;
        }

        $currentUnits = BloodStock::query()
            ->where('hospital_id', $hospitalId)
            ->where('blood_type', $bloodType)
            ->where('status', self::STATUS_AVAILABLE)
            ->count();

        if ($currentUnits < $threshold->min_units) {
            $exists = SmartAlert::query()
                ->where('hospital_id', $hospitalId)
                ->where('blood_type', $bloodType)
                ->where('status', 'active')
                ->exists();

            if (! $exists) {
                SmartAlert::query()->create([
                    'hospital_id' => $hospitalId,
                    'blood_type' => $bloodType,
                    'current_units' => $currentUnits,
                    'threshold_units' => $threshold->min_units,
                    'status' => 'active',
                    'triggered_at' => now(),
                ]);
            }

            return;
        }

        SmartAlert::query()
            ->where('hospital_id', $hospitalId)
            ->where('blood_type', $bloodType)
            ->where('status', 'active')
            ->update([
                'status' => 'resolved',
                'resolved_at' => now(),
                'current_units' => $currentUnits,
            ]);
    }

    private function recordMovement(
        BloodStock $stock,
        string $movementType,
        ?string $fromStatus,
        ?string $toStatus,
        int $availableDelta,
        string $sourceType,
        int $sourceId,
        ?int $actorId,
        ?string $notes,
        string $idempotencyKey,
    ): void {
        BloodStockMovement::query()->firstOrCreate(
            ['idempotency_key' => $idempotencyKey],
            [
                'hospital_id' => $stock->hospital_id,
                'blood_stock_id' => $stock->id,
                'donation_history_id' => $stock->donation_history_id,
                'blood_type' => $stock->blood_type,
                'movement_type' => $movementType,
                'from_status' => $fromStatus,
                'to_status' => $toStatus,
                'quantity_units' => 1,
                'volume_ml' => $stock->volume_ml,
                'available_delta' => $availableDelta,
                'actor_id' => $actorId,
                'source_type' => $sourceType,
                'source_id' => $sourceId,
                'notes' => $notes,
                'occurred_at' => now(),
            ],
        );
    }

    private function assertAllowedTransition(string $fromStatus, string $toStatus): void
    {
        $allowed = [
            self::STATUS_PROCESSING => [self::STATUS_AVAILABLE, self::STATUS_ALLOCATED, self::STATUS_DISCARDED],
            self::STATUS_AVAILABLE => [self::STATUS_ALLOCATED, self::STATUS_USED, self::STATUS_EXPIRED, self::STATUS_DISCARDED],
            self::STATUS_ALLOCATED => [self::STATUS_PROCESSING, self::STATUS_AVAILABLE, self::STATUS_USED],
        ];

        if (! in_array($toStatus, $allowed[$fromStatus] ?? [], true)) {
            throw ValidationException::withMessages([
                'status' => "Không thể chuyển túi máu từ {$fromStatus} sang {$toStatus}.",
            ]);
        }
    }

    private function availableDelta(string $fromStatus, string $toStatus): int
    {
        $fromAvailable = $fromStatus === self::STATUS_AVAILABLE;
        $toAvailable = $toStatus === self::STATUS_AVAILABLE;

        return (int) $toAvailable - (int) $fromAvailable;
    }
}
