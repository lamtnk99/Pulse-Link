<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\ChatConversation;
use App\Models\ChatMessage;
use App\Services\Contracts\AiChatService;
use App\Services\Mobile\MobileUserResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ChatController extends Controller
{
    public function __construct(
        private readonly MobileUserResolver $mobileUserResolver,
        private readonly AiChatService $aiChatService
    ) {}

    public function index(Request $request): JsonResponse
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));

        $conversations = ChatConversation::where('user_id', $user->id)
            ->with(['latestMessage'])
            ->latest()
            ->get();

        return response()->json([
            'data' => $conversations
        ]);
    }

    public function show(Request $request, ChatConversation $chat): JsonResponse
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));
        abort_unless((int) $chat->user_id === (int) $user->id, 403);

        $chat->load(['messages' => function ($q) {
            $q->oldest();
        }]);

        return response()->json([
            'data' => $chat
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));

        $request->validate([
            'context_type' => 'in:general,post_donation_checkup',
            'context_meta' => 'nullable|array',
        ]);

        $conversation = ChatConversation::create([
            'user_id' => $user->id,
            'title' => $request->input('title', 'Cuộc trò chuyện mới'),
            'context_type' => $request->input('context_type', 'general'),
            'context_meta' => $request->input('context_meta'),
            'is_active' => true,
        ]);

        return response()->json([
            'data' => $conversation
        ], 210); // Laravel standard returns
    }

    public function sendMessage(Request $request, ChatConversation $chat): JsonResponse
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));
        abort_unless((int) $chat->user_id === (int) $user->id, 403);

        $request->validate([
            'content' => 'required|string|max:5000',
        ]);

        $content = $request->input('content');

        // Quota check
        $quota = $this->getUserQuota($user->id);
        if ($quota['limit'] > 0 && $quota['used'] >= $quota['limit']) {
            return response()->json([
                'message' => "Bạn đã sử dụng hết giới hạn {$quota['limit']} tin nhắn hàng ngày của Trợ lý Sức khỏe AI. Vui lòng quay lại vào ngày mai!",
                'used' => $quota['used'],
                'limit' => $quota['limit'],
                'remaining' => 0
            ], 429);
        }

        // 1. Save user message
        $userMessage = ChatMessage::create([
            'chat_conversation_id' => $chat->id,
            'role' => 'user',
            'content' => $content,
        ]);

        // Auto update conversation title if default title
        if ($chat->title === 'Cuộc trò chuyện mới' || $chat->title === 'New Conversation') {
            $chat->update([
                'title' => mb_strimwidth($content, 0, 30, '...')
            ]);
        }

        // 2. Prepare Health Context
        $healthContext = [
            'name' => $user->name,
            'blood_type' => $user->blood_type,
            'total_donations' => $user->total_donations,
            'last_donation_date' => $user->last_donation_date,
        ];

        // 3. Call AI
        try {
            $aiResponse = $this->aiChatService->generateReply($chat, $content, $healthContext);
        } catch (\Exception $e) {
            return response()->json([
                'message' => "Có lỗi xảy ra khi kết nối với AI: " . $e->getMessage()
            ], 500);
        }

        // 4. Save AI message
        $aiMessage = ChatMessage::create([
            'chat_conversation_id' => $chat->id,
            'role' => 'assistant',
            'content' => $aiResponse->content,
            'metadata' => [
                'provider_used' => $aiResponse->providerUsed,
                'tokens_used' => $aiResponse->tokensUsed,
            ],
        ]);

        // Recalculate remaining quota after sending
        $newQuota = $this->getUserQuota($user->id);

        return response()->json([
            'data' => $aiMessage,
            'quota' => $newQuota
        ]);
    }

    public function activeCheckup(Request $request): JsonResponse
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));

        // 1. Quét các context đặc biệt đang active
        $conversation = ChatConversation::where('user_id', $user->id)
            ->whereIn('context_type', [
                ChatConversation::CONTEXT_POST_DONATION_CHECKUP,
                ChatConversation::CONTEXT_APPOINTMENT_REMINDER,
                ChatConversation::CONTEXT_PRE_DONATION_GUIDANCE,
                ChatConversation::CONTEXT_DONATION_DEFERRED,
            ])
            ->where('is_active', true)
            ->with(['latestMessage'])
            ->latest()
            ->first();

        // 2. Nếu không có context đặc biệt, trả về hoặc tạo cuộc trò chuyện general và thêm lời chào thấu cảm hàng ngày
        if (!$conversation) {
            $conversation = ChatConversation::where('user_id', $user->id)
                ->where('context_type', ChatConversation::CONTEXT_GENERAL)
                ->where('is_active', true)
                ->latest()
                ->first();

            if (!$conversation) {
                $conversation = ChatConversation::create([
                    'user_id' => $user->id,
                    'title' => 'Trợ lý Sức khỏe AI',
                    'context_type' => ChatConversation::CONTEXT_GENERAL,
                    'is_active' => true,
                ]);
            }

            // Kiểm tra xem hôm nay đã gửi lời chào hàng ngày chưa
            $hasDailyGreetingToday = ChatMessage::where('chat_conversation_id', $conversation->id)
                ->where('role', 'assistant')
                ->where('content', 'like', '%Chào%')
                ->whereDate('created_at', today())
                ->exists();

            if (!$hasDailyGreetingToday) {
                // Tạo lời chào thấu cảm theo thời gian thực (Giờ địa phương hoặc UTC tùy cấu hình - dùng Carbon hỗ trợ múi giờ)
                $hour = now()->timezone('Asia/Ho_Chi_Minh')->hour;
                $greeting = "Chào bạn! Chúc bạn một ngày mới tốt lành. ❤️";
                if ($hour >= 5 && $hour < 12) {
                    $greeting = "Chào buổi sáng {$user->name}! Chúc bạn một ngày mới tràn đầy năng lượng tích cực. Hãy nhớ uống một cốc nước lọc ấm để khởi đầu ngày mới nhé! ☀️";
                } elseif ($hour >= 12 && $hour < 18) {
                    $greeting = "Chào {$user->name}, nửa ngày đã trôi qua rồi. Bạn đã dành vài phút để nghỉ ngơi và uống nước chưa? Hãy cùng thư giãn một chút nhé! ☕";
                } else {
                    $greeting = "Chào buổi tối {$user->name}! Một ngày vất vả đã trôi qua, hãy nghỉ ngơi thật tốt và chuẩn bị cho một giấc ngủ thật ngon để cơ thể tái tạo máu tốt nhất nhé! 💤";
                }

                ChatMessage::create([
                    'chat_conversation_id' => $conversation->id,
                    'role' => 'assistant',
                    'content' => $greeting,
                ]);

                // Tải lại tin nhắn mới nhất
                $conversation->load('latestMessage');
            }
        }

        return response()->json([
            'data' => $conversation
        ]);
    }

    public function quota(Request $request): JsonResponse
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));
        return response()->json([
            'data' => $this->getUserQuota($user->id)
        ]);
    }

    private function getUserQuota(int $userId): array
    {
        $limit = (int) AppSetting::get('chat_daily_limit', 0);
        
        $used = ChatMessage::whereHas('conversation', function ($q) use ($userId) {
                $q->where('user_id', $userId);
            })
            ->where('role', 'user')
            ->whereDate('created_at', today())
            ->count();

        $remaining = $limit > 0 ? max(0, $limit - $used) : 999999; // Represents unlimited

        return [
            'used' => $used,
            'limit' => $limit,
            'remaining' => $limit > 0 ? $remaining : -1, // -1 means unlimited
        ];
    }
}
