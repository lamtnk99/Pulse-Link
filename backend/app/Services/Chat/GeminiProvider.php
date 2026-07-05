<?php

namespace App\Services\Chat;

use App\Models\AppSetting;
use App\Models\ChatConversation;
use App\Services\Contracts\AiChatResponse;
use App\Domain\Health\HealthKnowledgeBase;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GeminiProvider
{
    public function generateReply(
        ChatConversation $conversation,
        string $userMessage,
        array $healthContext = []
    ): AiChatResponse {
        $apiKey = AppSetting::get('gemini_api_key') ?: config('services.gemini.key');

        if (empty($apiKey)) {
            throw new \Exception("Gemini API key is not configured.");
        }

        // Get recent history
        $historyMessages = $conversation->messages()
            ->whereIn('role', ['user', 'assistant'])
            ->oldest()
            ->take(15)
            ->get();

        $contents = [];
        foreach ($historyMessages as $msg) {
            $contents[] = [
                'role' => $msg->role === 'assistant' ? 'model' : 'user',
                'parts' => [['text' => $msg->content]]
            ];
        }

        // Add the current message
        $contents[] = [
            'role' => 'user',
            'parts' => [['text' => $userMessage]]
        ];

        // Build system prompt
        $systemPrompt = $this->buildSystemPrompt($conversation, $healthContext);

        $model = AppSetting::get('gemini_model_name', 'gemini-2.5-flash');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}";

        Log::info("GeminiProvider: Sending request to model {$model}");

        $response = Http::timeout(10)
            ->post($url, [
                'contents' => $contents,
                'systemInstruction' => [
                    'parts' => [['text' => $systemPrompt]]
                ],
                'generationConfig' => [
                    'temperature' => 0.4,
                    'maxOutputTokens' => 800,
                ]
            ]);

        if ($response->failed()) {
            Log::error("Gemini API failed: " . $response->body());
            throw new \Exception("Gemini API returned status code " . $response->status() . ": " . $response->body());
        }

        $data = $response->json();
        $text = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';
        
        if (empty($text)) {
            throw new \Exception("Gemini API returned an empty response.");
        }

        return new AiChatResponse(
            content: trim($text),
            providerUsed: 'gemini',
            tokensUsed: 0 // Free tier usually doesn't return exact tokens in standard format easily, or we can check usageMetadata
        );
    }

    private function buildSystemPrompt(ChatConversation $conversation, array $context): string
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

        $contextInstruction = "";
        switch ($conversation->context_type) {
            case ChatConversation::CONTEXT_PRE_DONATION_GUIDANCE:
                $meta = $conversation->context_meta;
                $eventTitle = $meta['event_title'] ?? 'Sự kiện hiến máu';
                $location = $meta['location_name'] ?? 'Điểm hiến máu';
                $startsAt = isset($meta['starts_at']) ? \Carbon\Carbon::parse($meta['starts_at'])->format('H:i d/m/Y') : 'Khung giờ đã đặt';
                
                $contextInstruction = "NGỮ CẢNH: Người dùng ĐÃ ĐĂNG KÝ LỊCH HIẾN MÁU thành công cho sự kiện \"{$eventTitle}\" tại {$location} vào lúc {$startsAt}.\n"
                    . "Nhiệm vụ của bạn:\n"
                    . "- Tư vấn dặn dò, giúp người dùng chuẩn bị thể trạng tốt nhất trước ngày hiến (ngủ đủ giấc, uống nước ấm, ăn nhẹ, tránh mỡ/sữa, tránh rượu bia).\n"
                    . "- Trả lời các thắc mắc về điều kiện hiến máu, giấy tờ cần mang theo, quy trình hiến máu.\n"
                    . "- Hãy thể hiện sự trân quý, nhiệt huyết và chu đáo khi hướng dẫn họ.\n\n";
                break;
            case ChatConversation::CONTEXT_APPOINTMENT_REMINDER:
                $meta = $conversation->context_meta;
                $eventTitle = $meta['event_title'] ?? 'Sự kiện hiến máu';
                $location = $meta['location_name'] ?? 'Điểm hiến máu';
                $startsAt = isset($meta['starts_at']) ? \Carbon\Carbon::parse($meta['starts_at'])->format('H:i') : 'Khung giờ đã đặt';

                $contextInstruction = "NGỮ CẢNH: Hôm nay là NGÀY HẸN HIẾN MÁU của người dùng tại sự kiện \"{$eventTitle}\" lúc {$startsAt} ở {$location}.\n"
                    . "Nhiệm vụ của bạn:\n"
                    . "- Dặn dò họ uống một cốc nước ấm lớn trước khi đi.\n"
                    . "- Hướng dẫn đường đi hoặc giải thích các câu hỏi về thủ tục đăng ký tại chỗ.\n"
                    . "- Thể hiện sự động viên tinh thần, trấn an nếu họ lo lắng.\n\n";
                break;
            case ChatConversation::CONTEXT_POST_DONATION_CHECKUP:
                $meta = $conversation->context_meta;
                $location = $meta['location_name'] ?? 'Điểm hiến máu';
                $donatedAt = isset($meta['donated_at']) ? \Carbon\Carbon::parse($meta['donated_at'])->format('d/m/Y') : 'gần đây';

                $contextInstruction = "NGỮ CẢNH: Người dùng VỪA HIẾN MÁU thành công tại {$location} vào ngày {$donatedAt}.\n"
                    . "Nhiệm vụ của bạn:\n"
                    . "- Hỏi thăm tỉ mỉ và chăm sóc sức khỏe sau hiến máu.\n"
                    . "- Nếu người dùng phản hồi bị chóng mặt, choáng váng: hướng dẫn sơ cứu lập tức (nằm xuống, kê cao chân, uống nước đường ấm, nghỉ ngơi tĩnh lặng).\n"
                    . "- Nếu người dùng bị bầm tím vết tiêm: khuyên chườm lạnh trong 24h đầu, sau đó chườm ấm.\n"
                    . "- Hướng dẫn thực đơn ăn uống bổ máu phục hồi sức khỏe.\n\n";
                break;
            case ChatConversation::CONTEXT_DONATION_DEFERRED:
                $meta = $conversation->context_meta;
                $eventTitle = $meta['event_title'] ?? 'Sự kiện hiến máu';
                $reason = $meta['screening_notes'] ?? '';

                $contextInstruction = "NGỮ CẢNH: Người dùng BỊ HOÃN HIẾN MÁU (không đủ điều kiện tạm thời) tại sự kiện \"{$eventTitle}\" do: {$reason}.\n"
                    . "Nhiệm vụ của bạn:\n"
                    . "- Hãy cực kỳ thấu cảm, an ủi tinh thần người dùng (tránh để họ cảm thấy có lỗi hay buồn tủi).\n"
                    . "- Giải thích cặn kẽ vì sao an toàn của người hiến là trên hết.\n"
                    . "- Tư vấn thực đơn ăn uống, bồi bổ cơ thể để sớm cải thiện chỉ số sức khỏe (ví dụ bổ sung sắt để tăng hồng cầu, ngủ đủ giấc để ổn định huyết áp).\n"
                    . "- Khích lệ họ chuẩn bị tốt nhất cho lần đăng ký sau.\n\n";
                break;
            case ChatConversation::CONTEXT_GENERAL:
            default:
                $contextInstruction = "NGỮ CẢNH: Cuộc trò chuyện tư vấn sức khỏe tổng quát hoặc chào hỏi thấu cảm hàng ngày.\n"
                    . "Nhiệm vụ của bạn:\n"
                    . "- Đưa ra các lời khuyên chào hỏi thấu cảm, nhắc nhở uống nước lọc, ngủ đủ giấc, giữ tinh thần lạc quan.\n"
                    . "- Thể hiện sự chu đáo, ân cần như một người bạn thân thiết đồng hành chăm sóc sức khỏe.\n\n";
                break;
        }

        return "Bạn là Trợ lý Sức khỏe AI thông thái và thân thiện của Pulse Link - hệ sinh thái hỗ trợ hiến máu khẩn cấp tại Việt Nam.\n"
            . "Nhiệm vụ của bạn là tư vấn sức khỏe tổng quát, trả lời các câu hỏi y tế thường gặp và hỗ trợ người hiến máu chăm sóc sức khỏe.\n\n"
            . "QUY TẮC AN TOÀN Y TẾ BẮT BUỘC:\n"
            . "1. Bạn chỉ được cung cấp thông tin mang tính tham khảo y khoa. Tuyệt đối KHÔNG tự chẩn đoán bệnh cụ thể hay kê đơn thuốc.\n"
            . "2. Nếu người dùng mô tả các triệu chứng nguy hiểm hoặc khẩn cấp (như khó thở, đau ngực, sốt cao kéo dài, ngất xỉu), hãy KHUYÊN họ gọi ngay cấp cứu 115 hoặc đến cơ sở y tế gần nhất.\n"
            . "3. Giữ thái độ thân thiện, nhân văn, thấu cảm và động viên người hiến máu.\n"
            . "4. Từ chối lịch sự nếu được hỏi các câu hỏi không liên quan đến sức khỏe, y học hoặc đời sống thường nhật.\n\n"
            . $contextInstruction
            . $donorInfo . "\n"
            . $knowledge;
    }
}
