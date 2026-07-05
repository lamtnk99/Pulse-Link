<?php

namespace App\Observers;

use App\Events\MobileNotificationCreated;
use App\Models\ChatConversation;
use App\Models\ChatMessage;
use App\Models\DonationAppointment;
use App\Models\MobileNotification;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class DonationAppointmentObserver
{
    public function created(DonationAppointment $appointment): void
    {
        if ($appointment->status !== 'booked') {
            return;
        }

        $this->createPreDonationChat($appointment);
    }

    public function updated(DonationAppointment $appointment): void
    {
        // 1. If status changed to booked (e.g. from cancelled back to booked)
        if ($appointment->wasChanged('status') && $appointment->status === 'booked') {
            $this->createPreDonationChat($appointment);
        }

        // 2. If status changed to deferred
        if ($appointment->wasChanged('status') && $appointment->status === 'deferred') {
            $this->createDeferredChat($appointment);
        }
    }

    private function createPreDonationChat(DonationAppointment $appointment): void
    {
        $user = $appointment->user;
        $event = $appointment->event;
        if (!$user || !$event) {
            return;
        }

        // Check if there is already an active pre-donation chat for this appointment
        $exists = ChatConversation::where('user_id', $user->id)
            ->where('context_type', ChatConversation::CONTEXT_PRE_DONATION_GUIDANCE)
            ->get()
            ->contains(function ($chat) use ($appointment) {
                $meta = $chat->context_meta;
                return isset($meta['appointment_id']) && ((int) $meta['appointment_id'] === (int) $appointment->id);
            });

        if ($exists) {
            return;
        }

        DB::transaction(function () use ($appointment, $user, $event) {
            $eventTitle = $event->title;
            $location = $event->location_name;
            $startsAt = Carbon::parse($event->starts_at)->format('H:i d/m/Y');

            // Create conversation
            $chat = ChatConversation::create([
                'user_id' => $user->id,
                'title' => 'Chuẩn bị hiến máu ' . Carbon::parse($event->starts_at)->format('d/m/Y'),
                'context_type' => ChatConversation::CONTEXT_PRE_DONATION_GUIDANCE,
                'context_meta' => [
                    'appointment_id' => $appointment->id,
                    'event_id' => $event->id,
                    'event_title' => $eventTitle,
                    'location_name' => $location,
                    'starts_at' => $event->starts_at->toIso8601String(),
                ],
                'is_active' => true,
            ]);

            // Welcome message
            $content = "Chào {$user->name}! 👋 Cảm ơn bạn đã đăng ký lịch hiến máu tại sự kiện \"{$eventTitle}\" vào lúc {$startsAt} ở {$location}.\n\n"
                . "Để hành trình hiến máu của bạn diễn ra an toàn và thuận lợi nhất, hãy ghi nhớ một số dặn dò từ mình nhé:\n"
                . "1. 💤 Ngủ đủ giấc (ít nhất 6 tiếng) vào đêm trước ngày hiến.\n"
                . "2. 🍳 Hãy ăn nhẹ trước khi hiến (tránh đồ ăn nhiều mỡ, sữa).\n"
                . "3. 💧 Uống nhiều nước lọc (300-500ml) trước khi hiến.\n"
                . "4. ❌ Tuyệt đối không sử dụng rượu bia, chất kích thích.\n\n"
                . "Chúc bạn có một trải nghiệm hiến máu thật ý nghĩa! Bạn có thắc mắc gì cần mình tư vấn thêm không? ❤️";

            ChatMessage::create([
                'chat_conversation_id' => $chat->id,
                'role' => 'assistant',
                'content' => $content,
                'metadata' => [
                    'is_auto_guidance' => true,
                ],
            ]);

            // Notification
            $notification = MobileNotification::create([
                'user_id' => $user->id,
                'type' => 'pre_donation_guidance',
                'title' => 'Dặn dò trước ngày hiến máu ❤️',
                'body' => "Chuẩn bị tốt nhất cho buổi hiến máu của bạn tại {$eventTitle} nhé.",
                'payload' => [
                    'conversation_id' => $chat->id,
                    'appointment_id' => $appointment->id,
                ],
            ]);

            try {
                event(new MobileNotificationCreated($notification));
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning("Broadcasting pre-donation notification failed: " . $e->getMessage());
            }
        });
    }

    private function createDeferredChat(DonationAppointment $appointment): void
    {
        $user = $appointment->user;
        $event = $appointment->event;
        if (!$user || !$event) {
            return;
        }

        // Check if there is already an active deferred chat for this appointment
        $exists = ChatConversation::where('user_id', $user->id)
            ->where('context_type', ChatConversation::CONTEXT_DONATION_DEFERRED)
            ->get()
            ->contains(function ($chat) use ($appointment) {
                $meta = $chat->context_meta;
                return isset($meta['appointment_id']) && ((int) $meta['appointment_id'] === (int) $appointment->id);
            });

        if ($exists) {
            return;
        }

        DB::transaction(function () use ($appointment, $user, $event) {
            $eventTitle = $event->title;

            // Create conversation
            $chat = ChatConversation::create([
                'user_id' => $user->id,
                'title' => 'Động viên & Bồi bổ sức khỏe',
                'context_type' => ChatConversation::CONTEXT_DONATION_DEFERRED,
                'context_meta' => [
                    'appointment_id' => $appointment->id,
                    'event_id' => $event->id,
                    'event_title' => $eventTitle,
                    'screening_notes' => $appointment->screening_notes,
                ],
                'is_active' => true,
            ]);

            // Welcome message
            $reason = $appointment->screening_notes ? " do: {$appointment->screening_notes}" : "";
            $content = "Chào {$user->name}! Mình biết hôm nay bạn chưa thể hoàn thành ca hiến máu tại sự kiện \"{$eventTitle}\"{$reason}. Cảm giác này có thể hơi tiếc nuối một chút, nhưng không sao cả đâu bạn nhé!\n\n"
                . "Sức khỏe của bạn mới là điều quan trọng số một. Rất nhiều người hiến máu tình nguyện cũng từng gặp các chỉ số tạm thời chưa đạt chuẩn (như huyết áp chưa ổn định, huyết sắc tố thấp, thiếu ngủ, v.v.).\n\n"
                . "🌸 Lời khuyên bồi bổ từ mình:\n"
                . "- Ăn thêm thực phẩm giàu sắt (thịt bò, gan, trứng, rau chân vịt, các loại hạt).\n"
                . "- Nghỉ ngơi điều độ, ngủ đủ giấc và uống nhiều nước ấm.\n"
                . "- Giữ tinh thần thoải mái để chuẩn bị cho lần hiến tiếp theo nhé!\n\n"
                . "Bạn có muốn mình tư vấn thực đơn bổ máu hay cách cải thiện chỉ số sức khỏe không? Cứ chia sẻ với mình nha! ❤️";

            ChatMessage::create([
                'chat_conversation_id' => $chat->id,
                'role' => 'assistant',
                'content' => $content,
                'metadata' => [
                    'is_auto_deferred' => true,
                ],
            ]);

            // Notification
            $notification = MobileNotification::create([
                'user_id' => $user->id,
                'type' => 'donation_deferred',
                'title' => 'Món quà sức khỏe dành riêng cho bạn ❤️',
                'body' => "Sức khỏe của bạn là ưu tiên số một. Hãy cùng Pulse Link bồi bổ cơ thể nhé.",
                'payload' => [
                    'conversation_id' => $chat->id,
                    'appointment_id' => $appointment->id,
                ],
            ]);

            try {
                event(new MobileNotificationCreated($notification));
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning("Broadcasting deferred notification failed: " . $e->getMessage());
            }
        });
    }
}
