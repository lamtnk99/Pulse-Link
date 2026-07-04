<?php

namespace App\Services\Chat;

use App\Models\AppSetting;
use App\Models\ChatConversation;
use App\Services\Contracts\AiChatResponse;
use App\Domain\Health\HealthKnowledgeBase;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GroqProvider
{
    public function generateReply(
        ChatConversation $conversation,
        string $userMessage,
        array $healthContext = []
    ): AiChatResponse {
        $apiKey = AppSetting::get('groq_api_key') ?: config('services.groq.key');

        if (empty($apiKey)) {
            throw new \Exception("Groq API key is not configured.");
        }

        // Get system prompt
        $systemPrompt = $this->buildSystemPrompt($healthContext);

        $messages = [
            ['role' => 'system', 'content' => $systemPrompt]
        ];

        // Get recent history
        $historyMessages = $conversation->messages()
            ->whereIn('role', ['user', 'assistant'])
            ->oldest()
            ->take(15)
            ->get();

        foreach ($historyMessages as $msg) {
            $messages[] = [
                'role' => $msg->role,
                'content' => $msg->content
            ];
        }

        // Add user message
        $messages[] = [
            'role' => 'user',
            'content' => $userMessage
        ];

        $model = AppSetting::get('groq_model_name', 'llama-3.3-70b-versatile');
        $url = "https://api.groq.com/openai/v1/chat/completions";

        Log::info("GroqProvider: Sending request to model {$model}");

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$apiKey}",
            'Content-Type' => 'application/json',
        ])
        ->timeout(10)
        ->post($url, [
            'model' => $model,
            'messages' => $messages,
            'temperature' => 0.4,
            'max_tokens' => 800,
        ]);

        if ($response->failed()) {
            Log::error("Groq API failed: " . $response->body());
            throw new \Exception("Groq API returned status code " . $response->status() . ": " . $response->body());
        }

        $data = $response->json();
        $text = $data['choices'][0]['message']['content'] ?? '';

        if (empty($text)) {
            throw new \Exception("Groq API returned an empty response.");
        }

        return new AiChatResponse(
            content: trim($text),
            providerUsed: 'groq',
            tokensUsed: $data['usage']['total_tokens'] ?? 0
        );
    }

    private function buildSystemPrompt(array $context): string
    {
        $knowledge = HealthKnowledgeBase::getKnowledgeString();
        
        $donorInfo = "";
        if (!empty($context)) {
            $donorInfo = "THÔNG TIN CÁ NHÂN NGƯỜI DÙNG:\n"
                . "- Họ tên: " . ($context['name'] ?? 'Người dùng') . "\n"
                . "- Nhóm máu: " . ($context['blood_type'] ?? 'Chưa xác định') . "\n"
                . "- Tổng số lần hiến máu: " . ($context['total_donations'] ?? 0) . "\n"
                . "- Ngày hiến gần nhất: " . ($context['last_donation_date'] ?? 'Chưa hiến lần nào') . "\n";
        }

        return "Bạn là Trợ lý Sức khỏe AI thông thái và thân thiện của Pulse Link - hệ sinh thái hỗ trợ hiến máu khẩn cấp tại Việt Nam.\n"
            . "Nhiệm vụ của bạn là tư vấn sức khỏe tổng quát, trả lời các câu hỏi y tế thường gặp và hỗ trợ người hiến máu chăm sóc sức khỏe.\n\n"
            . "QUY TẮC AN TOÀN Y TẾ BẮT BUỘC:\n"
            . "1. Bạn chỉ được cung cấp thông tin mang tính tham khảo y khoa. Tuyệt đối KHÔNG tự chẩn đoán bệnh cụ thể hay kê đơn thuốc.\n"
            . "2. Nếu người dùng mô tả các triệu chứng nguy hiểm hoặc khẩn cấp (như khó thở, đau ngực, sốt cao kéo dài, ngất xỉu), hãy KHUYÊN họ gọi ngay cấp cứu 115 hoặc đến cơ sở y tế gần nhất.\n"
            . "3. Giữ thái độ thân thiện, nhân văn, thấu cảm và động viên người hiến máu.\n"
            . "4. Từ chối lịch sự nếu được hỏi các câu hỏi không liên quan đến sức khỏe, y học hoặc đời sống thường nhật.\n\n"
            . $donorInfo . "\n"
            . $knowledge;
    }
}
