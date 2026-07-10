<?php

namespace App\Services\Privacy;

use App\Models\AccountDeletionLog;
use App\Models\BloodJourney;
use App\Models\CampaignDonation;
use App\Models\ChatConversation;
use App\Models\DonationAppointment;
use App\Models\DonationHistory;
use App\Models\EmergencyAlertRecipient;
use App\Models\EmergencyCommitment;
use App\Models\MobileNotification;
use App\Models\NotificationDevice;
use App\Models\NotificationPreference;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class AccountDeletionService
{
    public function deleteDonor(User $user, ?string $reason = null): void
    {
        abort_unless($user->role === 'donor', 403, 'Endpoint này chỉ dành cho tài khoản người hiến.');

        DB::transaction(function () use ($user, $reason): void {
            $user->tokens()->delete();
            DB::table('password_reset_tokens')
                ->where('email', $user->email)
                ->delete();
            DB::table('sessions')
                ->where('user_id', $user->id)
                ->delete();
            $this->deleteIdentityImages($user);

            ChatConversation::query()
                ->where('user_id', $user->id)
                ->delete();

            MobileNotification::query()
                ->where('user_id', $user->id)
                ->delete();

            NotificationDevice::query()
                ->where('user_id', $user->id)
                ->delete();

            NotificationPreference::query()
                ->where('user_id', $user->id)
                ->delete();

            EmergencyAlertRecipient::query()
                ->where('user_id', $user->id)
                ->delete();

            DonationAppointment::query()
                ->where('user_id', $user->id)
                ->update([
                    'user_id' => null,
                    'cancel_reason' => DB::raw("COALESCE(cancel_reason, 'Tài khoản người hiến đã được xóa theo yêu cầu.')"),
                ]);

            DonationHistory::query()
                ->where('user_id', $user->id)
                ->update([
                    'user_id' => null,
                    'notes' => null,
                ]);

            EmergencyCommitment::query()
                ->where('donor_id', $user->id)
                ->update([
                    'donor_id' => null,
                    'latitude' => null,
                    'longitude' => null,
                    'last_location_at' => null,
                ]);

            BloodJourney::query()
                ->where('donor_id', $user->id)
                ->update(['donor_id' => null]);

            CampaignDonation::query()
                ->where('user_id', $user->id)
                ->update([
                    'user_id' => null,
                    'donor_name' => 'Hiệp sĩ ẩn danh',
                    'is_anonymous' => true,
                ]);

            AccountDeletionLog::query()->create([
                'user_hash' => hash('sha256', 'user:'.$user->id.':'.config('app.key')),
                'email_hash' => hash('sha256', 'email:'.Str::lower((string) $user->email).':'.config('app.key')),
                'role' => $user->role,
                'reason' => $reason,
                'status' => 'completed',
                'deleted_at' => now(),
            ]);

            $user->forceDelete();
        });
    }

    private function deleteIdentityImages(User $user): void
    {
        foreach ([$user->id_card_front_url, $user->id_card_back_url] as $url) {
            if (! is_string($url) || $url === '') {
                continue;
            }

            $path = parse_url($url, PHP_URL_PATH);
            if (! is_string($path)) {
                continue;
            }

            $storagePrefix = '/storage/';
            $position = strpos($path, $storagePrefix);
            if ($position === false) {
                continue;
            }

            $relativePath = substr($path, $position + strlen($storagePrefix));
            if ($relativePath !== '' && str_starts_with($relativePath, 'pulse-link/id-cards/')) {
                Storage::disk('public')->delete($relativePath);
            }
        }
    }
}
