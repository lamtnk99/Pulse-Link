<?php

namespace App\Services\Chat;

use App\Models\AppSetting;
use App\Models\ChatConversation;
use App\Services\Contracts\AiChatResponse;
use App\Services\Contracts\AiChatService;
use Illuminate\Support\Facades\Log;

class FallbackAiChatService implements AiChatService
{
    protected GeminiProvider $gemini;
    protected GroqProvider $groq;

    public function __construct(GeminiProvider $gemini, GroqProvider $groq)
    {
        $this->gemini = $gemini;
        $this->groq = $groq;
    }

    public function generateReply(
        ChatConversation $conversation,
        string $userMessage,
        array $healthContext = []
    ): AiChatResponse {
        $primary = AppSetting::get('ai_primary_provider', 'gemini');
        
        Log::info("FallbackAiChatService: Preferred provider is '{$primary}'");

        if ($primary === 'groq') {
            try {
                return $this->groq->generateReply($conversation, $userMessage, $healthContext);
            } catch (\Exception $e) {
                Log::warning("Primary provider 'groq' failed, falling back to 'gemini'. Error: " . $e->getMessage());
                try {
                    return $this->gemini->generateReply($conversation, $userMessage, $healthContext);
                } catch (\Exception $ex) {
                    Log::error("Both 'groq' and 'gemini' failed. Secondary error: " . $ex->getMessage());
                    return $this->getStaticFallbackResponse();
                }
            }
        } else {
            // Default to gemini first
            try {
                return $this->gemini->generateReply($conversation, $userMessage, $healthContext);
            } catch (\Exception $e) {
                Log::warning("Primary provider 'gemini' failed, falling back to 'groq'. Error: " . $e->getMessage());
                try {
                    return $this->groq->generateReply($conversation, $userMessage, $healthContext);
                } catch (\Exception $ex) {
                    Log::error("Both 'gemini' and 'groq' failed. Secondary error: " . $ex->getMessage());
                    return $this->getStaticFallbackResponse();
                }
            }
        }
    }

    protected function getStaticFallbackResponse(): AiChatResponse
    {
        $message = "Xin lỗi bạn, hiện tại tất cả các kênh kết nối AI sức khỏe đang tạm thời quá tải hoặc chưa được cấu hình API Key chính xác từ ban quản trị.\n\n"
            . "Lời khuyên nhanh: Nếu đây là ca khẩn cấp hoặc bạn cảm thấy mệt mỏi/chóng mặt nhiều sau hiến máu, hãy dành thời gian nằm nghỉ ngơi, uống nhiều nước ấm và liên hệ hotline y tế/bệnh viện gần nhất để được nhân viên y tế hỗ trợ kịp thời nhé!";

        return new AiChatResponse(
            content: $message,
            providerUsed: 'static_fallback',
            tokensUsed: 0
        );
    }
}
