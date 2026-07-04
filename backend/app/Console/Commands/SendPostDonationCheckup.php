<?php

namespace App\Console\Commands;

use App\Events\MobileNotificationCreated;
use App\Models\ChatConversation;
use App\Models\ChatMessage;
use App\Models\DonationHistory;
use App\Models\MobileNotification;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SendPostDonationCheckup extends Command
{
    protected $signature = 'app:send-post-donation-checkup';

    protected $description = 'Gửi tin nhắn hỏi thăm sức khỏe tự động sau 24h-48h kể từ ca hiến máu';

    public function handle(): int
    {
        $this->info('Bắt đầu quét danh sách hiến máu để gửi tin hỏi thăm...');

        // Scan yesterday (24h) and day before yesterday (48h)
        $startDate = Carbon::today()->subDays(2)->startOfDay();
        $endDate = Carbon::today()->subDays(1)->endOfDay();

        $donations = DonationHistory::with(['user', 'hospital'])
            ->whereBetween('donated_at', [$startDate, $endDate])
            ->where('status', 'verified')
            ->get();

        $this->info("Tìm thấy " . $donations->count() . " lượt hiến máu trong khoảng 24h-48h qua.");

        $sentCount = 0;

        foreach ($donations as $donation) {
            if (!$donation->user) {
                continue;
            }

            // Check if checkup chat already exists for this donation history
            $exists = ChatConversation::where('user_id', $donation->user_id)
                ->where('context_type', 'post_donation_checkup')
                ->get()
                ->contains(function ($chat) use ($donation) {
                    $meta = $chat->context_meta;
                    return isset($meta['donation_history_id']) && 
                        ((int) $meta['donation_history_id'] === (int) $donation->id);
                });

            if ($exists) {
                continue;
            }

            DB::transaction(function () use ($donation, &$sentCount) {
                $hospitalName = $donation->hospital?->name ?? $donation->location_name;
                $donatedDate = Carbon::parse($donation->donated_at);
                $diffInDays = Carbon::today()->diffInDays($donatedDate);
                
                $timeSinceText = $diffInDays >= 2 ? '48' : '24';

                // 1. Create checkup conversation
                $chat = ChatConversation::create([
                    'user_id' => $donation->user_id,
                    'title' => 'Hỏi thăm sức khỏe ngày ' . $donatedDate->format('d/m/Y'),
                    'context_type' => 'post_donation_checkup',
                    'context_meta' => [
                        'donation_history_id' => $donation->id,
                        'donated_at' => $donation->donated_at,
                        'blood_type' => $donation->blood_type,
                        'volume_ml' => $donation->volume_ml,
                        'location_name' => $hospitalName,
                    ],
                    'is_active' => true,
                ]);

                // 2. Create the first care message from AI
                $content = "Chào {$donation->user->name}! 👋 Đã khoảng {$timeSinceText} giờ kể từ khi bạn hiến máu nhóm {$donation->blood_type} tại {$hospitalName}.\n\n"
                    . "Pulse Link muốn hỏi thăm xem sức khỏe của bạn hiện tại thế nào? Bạn có cảm thấy chóng mặt, mệt mỏi hay có vết bầm tím nào quanh vị trí tiêm không? Hãy chia sẻ để mình hỗ trợ tư vấn chăm sóc sức khỏe nhé! ❤️";

                ChatMessage::create([
                    'chat_conversation_id' => $chat->id,
                    'role' => 'assistant',
                    'content' => $content,
                    'metadata' => [
                        'is_auto_checkup' => true,
                    ],
                ]);

                // 3. Create MobileNotification
                $notification = MobileNotification::create([
                    'user_id' => $donation->user_id,
                    'type' => 'post_donation_checkup',
                    'title' => 'Pulse Link hỏi thăm sức khỏe ❤️',
                    'body' => "Chúng tôi muốn biết tình hình sức khỏe của bạn sau ca hiến máu tại {$hospitalName}.",
                    'payload' => [
                        'conversation_id' => $chat->id,
                        'donation_history_id' => $donation->id,
                    ],
                ]);

                // 4. Broadcast notification event
                event(new MobileNotificationCreated($notification));
                
                $sentCount++;
            });
        }

        $this->info("Đã gửi thành công {$sentCount} tin nhắn hỏi thăm sức khỏe.");
        return Command::SUCCESS;
    }
}
