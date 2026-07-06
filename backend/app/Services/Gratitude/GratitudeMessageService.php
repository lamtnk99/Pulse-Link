<?php

namespace App\Services\Gratitude;

use App\Models\AppSetting;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Sinh lời cảm ơn cá nhân hóa gửi tới người hiến máu khi hành trình giọt máu
 * hoàn tất.
 *
 * Tái sử dụng cùng cấu hình provider (Gemini / Groq) và API key với trợ lý
 * sức khỏe. Nếu chưa cấu hình key hoặc AI lỗi, tự động rơi về lời cảm ơn tĩnh
 * truyền vào qua $fallback — nên tính năng luôn an toàn kể cả ở bản demo.
 */
class GratitudeMessageService
{
    /**
     * @param array{donor_name?:string, blood_type?:string, hospital_name?:string, destination_type?:string} $context
     */
    public function generate(array $context, string $fallback): string
    {
        $primary = AppSetting::get('ai_primary_provider', 'gemini');
        $providers = $primary === 'groq' ? ['groq', 'gemini'] : ['gemini', 'groq'];

        foreach ($providers as $provider) {
            try {
                $message = $provider === 'groq'
                    ? $this->viaGroq($context)
                    : $this->viaGemini($context);

                $message = $this->sanitize($message);
                if ($message !== '') {
                    return $message;
                }
            } catch (\Throwable $e) {
                Log::warning("GratitudeMessageService: provider '{$provider}' failed: " . $e->getMessage());
            }
        }

        return $fallback;
    }

    private function viaGemini(array $context): string
    {
        $apiKey = AppSetting::get('gemini_api_key') ?: config('services.gemini.key');
        if (empty($apiKey)) {
            throw new \Exception('Gemini API key is not configured.');
        }

        $model = AppSetting::get('gemini_model_name', 'gemini-2.5-flash');
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}";

        $response = Http::timeout(12)->post($url, [
            'contents' => [
                ['role' => 'user', 'parts' => [['text' => $this->buildUserPrompt($context)]]],
            ],
            'systemInstruction' => [
                'parts' => [['text' => $this->systemPrompt($context)]],
            ],
            'generationConfig' => [
                'temperature' => 0.9,
                'maxOutputTokens' => 260,
            ],
        ]);

        if ($response->failed()) {
            throw new \Exception('Gemini API returned status ' . $response->status());
        }

        return (string) ($response->json()['candidates'][0]['content']['parts'][0]['text'] ?? '');
    }

    private function viaGroq(array $context): string
    {
        $apiKey = AppSetting::get('groq_api_key') ?: config('services.groq.key');
        if (empty($apiKey)) {
            throw new \Exception('Groq API key is not configured.');
        }

        $model = AppSetting::get('groq_model_name', 'llama-3.3-70b-versatile');

        $response = Http::withHeaders([
            'Authorization' => "Bearer {$apiKey}",
            'Content-Type' => 'application/json',
        ])->timeout(12)->post('https://api.groq.com/openai/v1/chat/completions', [
            'model' => $model,
            'messages' => [
                ['role' => 'system', 'content' => $this->systemPrompt($context)],
                ['role' => 'user', 'content' => $this->buildUserPrompt($context)],
            ],
            'temperature' => 0.9,
            'max_tokens' => 260,
        ]);

        if ($response->failed()) {
            throw new \Exception('Groq API returned status ' . $response->status());
        }

        return (string) ($response->json()['choices'][0]['message']['content'] ?? '');
    }

    private function systemPrompt(array $context): string
    {
        $isReserve = ($context['destination_type'] ?? 'patient') === 'reserve';

        $voice = $isReserve
            ? "Bạn viết với giọng của đội ngũ y bác sĩ tuyến đầu — những người vừa trải qua ca trực căng thẳng, giờ thở phào nhẹ nhõm và thật lòng biết ơn."
            : "Bạn viết với giọng của người nhà bệnh nhân vừa thoát khỏi ranh giới sinh tử — run rẩy, nghẹn ngào, biết ơn từ tận đáy lòng.";

        return "Bạn là người viết lời cảm ơn cho Pulse Link - hệ sinh thái hiến máu tại Việt Nam.\n"
            . "Nhiệm vụ: viết MỘT lời cảm ơn ngắn, THẬT LÒNG, chạm tới cảm xúc sâu nhất, gửi tới người vừa hiến máu.\n\n"
            . $voice . "\n\n"
            . "QUY TẮC:\n"
            . "1. Độ dài 2-3 câu, tiếng Việt tự nhiên, mộc mạc như lời nói từ trái tim, KHÔNG được giống văn mẫu hay template.\n"
            . "2. Gọi tên người hiến nếu được cung cấp, xưng hô gần gũi (anh/chị/bạn).\n"
            . "3. PHẢI có chi tiết cảm xúc cụ thể — ví dụ: nỗi lo lắng trước đó, khoảnh khắc nhận tin, cảm giác khi biết máu đã truyền thành công.\n"
            . "4. Mỗi lần phải viết KHÁC NHAU, tránh lặp lại cấu trúc câu hay từ ngữ với các lần trước.\n"
            . "5. TUYỆT ĐỐI KHÔNG bịa chi tiết y tế cụ thể (tên bệnh, kết quả xét nghiệm, tiên lượng).\n"
            . "6. Không dùng markdown, không emoji quá 1 cái, không ký tên, không tiêu đề.\n"
            . "7. Chỉ trả về đúng nội dung lời cảm ơn, không thêm lời dẫn hay giải thích.";
    }

    private function buildUserPrompt(array $context): string
    {
        $donor = trim((string) ($context['donor_name'] ?? '')) ?: 'người hiến máu';
        $bloodType = trim((string) ($context['blood_type'] ?? ''));
        $hospital = trim((string) ($context['hospital_name'] ?? ''));
        $isReserve = ($context['destination_type'] ?? 'patient') === 'reserve';

        $scenario = $isReserve
            ? "Ca cấp cứu đã đủ máu và ổn định; đơn vị máu vừa hiến được lưu vào kho máu dự trữ, sẵn sàng cứu những bệnh nhân tiếp theo."
            : "Đơn vị máu vừa hiến đã được truyền trực tiếp cho một bệnh nhân đang cấp cứu.";

        $lines = [
            "Người hiến: {$donor}",
        ];
        if ($bloodType !== '') {
            $lines[] = "Nhóm máu: {$bloodType}";
        }
        if ($hospital !== '') {
            $lines[] = "Bệnh viện: {$hospital}";
        }
        $lines[] = "Bối cảnh: {$scenario}";
        $lines[] = "";
        $lines[] = "Hãy viết lời cảm ơn gửi tới {$donor}.";

        return implode("\n", $lines);
    }

    private function sanitize(string $text): string
    {
        $text = trim($text);
        // Bỏ dấu ngoặc kép bao ngoài nếu model tự thêm.
        $text = trim($text, "\"'“”");
        // Gộp khoảng trắng thừa, giữ tối đa hợp lý.
        $text = preg_replace('/\s+/u', ' ', $text) ?? $text;

        return trim($text);
    }
}
