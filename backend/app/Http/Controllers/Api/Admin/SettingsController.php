<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Services\Admin\AdminUserResolver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SettingsController extends Controller
{
    public function __construct(
        private readonly AdminUserResolver $adminUserResolver,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($admin->role === 'system_admin', 403);

        $geminiKey = AppSetting::get('gemini_api_key');
        $groqKey = AppSetting::get('groq_api_key');

        $maskedGemini = null;
        if (!empty($geminiKey)) {
            $maskedGemini = 'sk-••••' . substr($geminiKey, -4);
        }

        $maskedGroq = null;
        if (!empty($groqKey)) {
            $maskedGroq = 'gsk_••••' . substr($groqKey, -4);
        }

        return response()->json([
            'data' => [
                'ai_primary_provider' => AppSetting::get('ai_primary_provider', 'gemini'),
                'gemini_api_key' => $maskedGemini,
                'gemini_model_name' => AppSetting::get('gemini_model_name', 'gemini-2.5-flash'),
                'groq_api_key' => $maskedGroq,
                'groq_model_name' => AppSetting::get('groq_model_name', 'llama-3.3-70b-versatile'),
                'chat_daily_limit' => (int) AppSetting::get('chat_daily_limit', 0),
            ]
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($admin->role === 'system_admin', 403);

        $request->validate([
            'ai_primary_provider' => 'required|in:gemini,groq',
            'gemini_api_key' => 'nullable|string',
            'gemini_model_name' => 'required|string',
            'groq_api_key' => 'nullable|string',
            'groq_model_name' => 'required|string',
            'chat_daily_limit' => 'nullable|integer|min:0',
        ]);

        AppSetting::set('ai_primary_provider', $request->input('ai_primary_provider'));
        AppSetting::set('gemini_model_name', $request->input('gemini_model_name'));
        AppSetting::set('groq_model_name', $request->input('groq_model_name'));
        AppSetting::set('chat_daily_limit', $request->input('chat_daily_limit', 0));

        if ($request->has('gemini_api_key') && !empty($request->input('gemini_api_key'))) {
            AppSetting::set('gemini_api_key', $request->input('gemini_api_key'));
        }

        if ($request->has('groq_api_key') && !empty($request->input('groq_api_key'))) {
            AppSetting::set('groq_api_key', $request->input('groq_api_key'));
        }

        return response()->json([
            'message' => 'Cập nhật cấu hình thành công.'
        ]);
    }

    public function testProvider(Request $request): JsonResponse
    {
        $admin = $this->adminUserResolver->resolve($request);
        abort_unless($admin->role === 'system_admin', 403);

        $request->validate([
            'provider' => 'required|in:gemini,groq',
            'api_key' => 'required|string',
        ]);

        $provider = $request->input('provider');
        $apiKey = $request->input('api_key');

        $oldKey = AppSetting::get($provider . '_api_key');

        try {
            AppSetting::set($provider . '_api_key', $apiKey);

            $response = null;

            DB::transaction(function () use ($provider, &$response, $admin) {
                $tempConversation = \App\Models\ChatConversation::create([
                    'user_id' => $admin->id,
                    'title' => 'Test Connection',
                    'context_type' => 'general',
                    'is_active' => false,
                ]);

                if ($provider === 'gemini') {
                    $prov = app(\App\Services\Chat\GeminiProvider::class);
                } else {
                    $prov = app(\App\Services\Chat\GroqProvider::class);
                }

                $response = $prov->generateReply($tempConversation, "Kiểm tra kết nối AI. Trả lời ngắn gọn bằng 1 từ: OK", []);

                throw new \Exception("Rollback DB changes");
            });
        } catch (\Exception $e) {
            // Restore old key
            if ($oldKey !== null) {
                AppSetting::set($provider . '_api_key', $oldKey);
            } else {
                \App\Models\AppSetting::where('key', $provider . '_api_key')->delete();
            }

            if ($e->getMessage() === "Rollback DB changes") {
                return response()->json([
                    'success' => true,
                    'message' => $response->content ?? 'Kết nối thành công.'
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => "Kết nối thất bại: " . $e->getMessage()
            ], 400);
        }

        return response()->json([
            'success' => false,
            'message' => "Kết nối thất bại."
        ], 400);
    }
}
