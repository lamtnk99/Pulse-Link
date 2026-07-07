<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MobileUploadController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'file' => ['required', 'file', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        $path = $payload['file']->store('pulse-link/id-cards', 'public');

        // Dựng URL theo đúng host của request thay vì APP_URL, để ảnh luôn truy
        // cập được từ chính địa chỉ mà client (mobile/web) đang gọi tới —
        // APP_URL mặc định (http://localhost) thường thiếu port và sai host.
        $publicUrl = $request->getSchemeAndHttpHost().'/storage/'.$path;

        return response()->json([
            'data' => [
                'path' => $path,
                'url' => $publicUrl,
            ],
        ], 201);
    }
}
