<?php

namespace App\Console\Commands;

use App\Events\MobileNotificationCreated;
use App\Models\ChatConversation;
use App\Models\ChatMessage;
use App\Models\DonationAppointment;
use App\Models\MobileNotification;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class SendAppointmentReminder extends Command
{
    protected $signature = 'app:send-appointment-reminder';

    protected $description = 'Gửi tin nhắn nhắc nhở chủ động ngày hiến máu cho người dùng có lịch hẹn hôm nay';

    public function handle(): int
    {
        $this->info('Bắt đầu quét lịch hiến hôm nay để gửi tin nhắc nhở...');

        $startDate = Carbon::today()->startOfDay();
        $endDate = Carbon::today()->endOfDay();

        $appointments = DonationAppointment::with(['user', 'event'])
            ->whereHas('event', function ($query) use ($startDate, $endDate) {
                $query->whereBetween('starts_at', [$startDate, $endDate]);
            })
            ->where('status', 'booked')
            ->get();

        $this->info("Tìm thấy " . $appointments->count() . " lịch hiến có sự kiện diễn ra hôm nay.");

        $sentCount = 0;

        foreach ($appointments as $appointment) {
            if (!$appointment->user || !$appointment->event) {
                continue;
            }

            // Check if reminder chat already exists for this appointment
            $exists = ChatConversation::where('user_id', $appointment->user_id)
                ->where('context_type', ChatConversation::CONTEXT_APPOINTMENT_REMINDER)
                ->get()
                ->contains(function ($chat) use ($appointment) {
                    $meta = $chat->context_meta;
                    return isset($meta['appointment_id']) && 
                        ((int) $meta['appointment_id'] === (int) $appointment->id);
                });

            if ($exists) {
                continue;
            }

            DB::transaction(function () use ($appointment, &$sentCount) {
                $user = $appointment->user;
                $event = $appointment->event;
                $eventTitle = $event->title;
                $location = $event->location_name;
                $startsAt = Carbon::parse($event->starts_at)->format('H:i');

                // 1. Create reminder conversation
                $chat = ChatConversation::create([
                    'user_id' => $user->id,
                    'title' => 'Nhắc hẹn hiến máu hôm nay',
                    'context_type' => ChatConversation::CONTEXT_APPOINTMENT_REMINDER,
                    'context_meta' => [
                        'appointment_id' => $appointment->id,
                        'event_id' => $event->id,
                        'event_title' => $eventTitle,
                        'location_name' => $location,
                        'starts_at' => $event->starts_at->toIso8601String(),
                    ],
                    'is_active' => true,
                ]);

                // 2. Create the first care message from AI
                $content = "Chào {$user->name}! Hôm nay là ngày hẹn hiến máu của bạn tại sự kiện \"{$eventTitle}\" lúc {$startsAt} ở {$location}.\n\n"
                    . "Pulse Link chúc bạn một ngày mới ngập tràn năng lượng! Bạn nhớ uống một ly nước lọc lớn trước khi di chuyển đến điểm hiến nhé. Mình có thể hỗ trợ chỉ đường hoặc hướng dẫn các giấy tờ cần chuẩn bị giúp bạn không?";

                ChatMessage::create([
                    'chat_conversation_id' => $chat->id,
                    'role' => 'assistant',
                    'content' => $content,
                    'metadata' => [
                        'is_auto_reminder' => true,
                    ],
                ]);

                // 3. Create MobileNotification
                $notification = MobileNotification::create([
                    'user_id' => $user->id,
                    'type' => 'appointment_reminder',
                    'title' => 'Nhắc lịch hẹn hiến máu hôm nay 🔔',
                    'body' => "Hẹn gặp lại bạn lúc {$startsAt} tại sự kiện {$eventTitle}.",
                    'payload' => [
                        'conversation_id' => $chat->id,
                        'appointment_id' => $appointment->id,
                    ],
                ]);

                // 4. Broadcast notification event
                try {
                    event(new MobileNotificationCreated($notification));
                } catch (\Throwable $e) {
                    \Illuminate\Support\Facades\Log::warning("Broadcasting appointment reminder notification failed: " . $e->getMessage());
                }
                
                $sentCount++;
            });
        }

        $this->info("Đã gửi thành công {$sentCount} tin nhắc nhở hẹn hiến.");
        return Command::SUCCESS;
    }
}
