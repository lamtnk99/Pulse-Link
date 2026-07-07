<?php

namespace App\Services\Donations;

use App\Events\MobileNotificationCreated;
use App\Models\ChatConversation;
use App\Models\ChatMessage;
use App\Models\DonationHistory;
use App\Models\MobileNotification;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;

class PostDonationCareService
{
    public function createForDonation(DonationHistory $donation): ?MobileNotification
    {
        $donation->loadMissing('user', 'hospital');

        if (! $donation->user) {
            return null;
        }

        $exists = ChatConversation::query()
            ->where('user_id', $donation->user_id)
            ->where('context_type', ChatConversation::CONTEXT_POST_DONATION_CHECKUP)
            ->get()
            ->contains(function (ChatConversation $chat) use ($donation): bool {
                $meta = $chat->context_meta ?? [];

                return isset($meta['donation_history_id'])
                    && (int) $meta['donation_history_id'] === (int) $donation->id;
            });

        if ($exists) {
            return null;
        }

        $hospitalName = $donation->hospital?->name ?? $donation->location_name;
        $donatedDate = Carbon::parse($donation->donated_at);
        $chat = ChatConversation::query()->create([
            'user_id' => $donation->user_id,
            'title' => 'Chăm sóc sau hiến máu '.$donatedDate->format('d/m/Y'),
            'context_type' => ChatConversation::CONTEXT_POST_DONATION_CHECKUP,
            'context_meta' => [
                'donation_history_id' => $donation->id,
                'donation_type' => $donation->donation_type,
                'donated_at' => $donation->donated_at?->toDateString(),
                'blood_type' => $donation->blood_type,
                'volume_ml' => $donation->volume_ml,
                'location_name' => $hospitalName,
            ],
            'is_active' => true,
        ]);

        ChatMessage::query()->create([
            'chat_conversation_id' => $chat->id,
            'role' => 'assistant',
            'content' => $this->careMessage($donation, $hospitalName),
            'metadata' => [
                'is_auto_checkup' => true,
            ],
        ]);

        $notification = MobileNotification::query()->create([
            'user_id' => $donation->user_id,
            'type' => 'post_donation_checkup',
            'title' => 'Hiến máu thành công',
            'body' => "Cảm ơn bạn đã hiến {$donation->volume_ml}ml máu nhóm {$donation->blood_type} tại {$hospitalName}. Pulse Link đã mở phần chăm sóc sau hiến cho bạn.",
            'payload' => [
                'conversation_id' => $chat->id,
                'donation_history_id' => $donation->id,
                'certificate_id' => $donation->certificate_id,
            ],
        ]);

        try {
            event(new MobileNotificationCreated($notification));
        } catch (\Throwable $exception) {
            Log::warning('Broadcasting post-donation care notification failed.', [
                'notification_id' => $notification->id,
                'message' => $exception->getMessage(),
            ]);
        }

        return $notification;
    }

    private function careMessage(DonationHistory $donation, string $hospitalName): string
    {
        return "Chào {$donation->user->name}! Bệnh viện đã ghi nhận ca hiến {$donation->volume_ml}ml máu nhóm {$donation->blood_type} của bạn tại {$hospitalName}.\n\n"
            . "Trong vài giờ tới, hãy nghỉ ngơi, uống thêm nước, ăn nhẹ và tránh vận động mạnh. Nếu bạn thấy chóng mặt, mệt bất thường, đau nhiều hoặc bầm tím lan rộng ở vị trí kim, cứ nhắn cho mình ngay để mình hướng dẫn cách chăm sóc phù hợp nhé.";
    }
}
