<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class MobileUploadController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $payload = $request->validate([
            'file' => ['required', 'file', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        $path = $payload['file']->store('pulse-link/id-cards', 'public');
        $publicUrl = Storage::disk('public')->url($path);

        return response()->json([
            'data' => [
                'path' => $path,
                'url' => str_starts_with($publicUrl, 'http')
                    ? $publicUrl
                    : $request->getSchemeAndHttpHost().$publicUrl,
            ],
        ], 201);
    }
}
