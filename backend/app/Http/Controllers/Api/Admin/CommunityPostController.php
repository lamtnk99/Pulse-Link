<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\CommunityPostResource;
use App\Models\CommunityPost;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CommunityPostController extends Controller
{
    public function index()
    {
        return CommunityPostResource::collection(
            CommunityPost::query()
                ->with('province', 'ward', 'hospital.province', 'hospital.ward', 'author')
                ->latest('published_at')
                ->latest()
                ->get()
        );
    }

    public function store(Request $request): JsonResponse
    {
        $payload = $this->validatedPayload($request);
        $payload['slug'] = $this->uniqueSlug($payload['title']);
        $payload = $this->normalizePublishState($payload);

        $post = CommunityPost::query()->create($payload);

        return response()->json([
            'data' => CommunityPostResource::make(
                $post->load('province', 'ward', 'hospital.province', 'hospital.ward', 'author')
            ),
        ], 201);
    }

    public function update(Request $request, CommunityPost $post): CommunityPostResource
    {
        $payload = $this->validatedPayload($request, partial: true);
        if (array_key_exists('title', $payload)) {
            $payload['slug'] = $this->uniqueSlug($payload['title'], $post->id);
        }
        $payload = $this->normalizePublishState($payload, $post);
        $post->update($payload);

        return CommunityPostResource::make(
            $post->refresh()->load('province', 'ward', 'hospital.province', 'hospital.ward', 'author')
        );
    }

    public function destroy(CommunityPost $post): JsonResponse
    {
        $post->delete();

        return response()->json(status: 204);
    }

    private function validatedPayload(Request $request, bool $partial = false): array
    {
        $prefix = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'hospital_id' => ['nullable', 'integer', 'exists:hospitals,id'],
            'author_id' => ['nullable', 'integer', 'exists:users,id'],
            'title' => [$prefix, 'string', 'max:255'],
            'excerpt' => ['nullable', 'string', 'max:1000'],
            'content' => [$prefix, 'string'],
            'image_url' => ['nullable', 'string', 'max:2048'],
            'status' => ['sometimes', 'in:draft,published'],
            'published_at' => ['nullable', 'date'],
            'audience_type' => ['sometimes', 'in:all,blood_type,hero_level,province'],
            'target_blood_type' => ['nullable', 'string', 'max:4'],
            'target_hero_level' => ['nullable', 'string', 'max:255'],
            'province_code' => ['nullable', 'string', 'size:2', 'exists:provinces,code'],
            'ward_code' => ['nullable', 'string', 'size:5', 'exists:wards,code'],
        ]);
    }

    private function normalizePublishState(array $payload, ?CommunityPost $post = null): array
    {
        if (($payload['status'] ?? $post?->status) === 'published' && empty($payload['published_at'])) {
            $payload['published_at'] = $post?->published_at ?? now();
        }

        return $payload;
    }

    private function uniqueSlug(string $title, ?int $ignoreId = null): string
    {
        $base = Str::slug($title);
        $slug = $base;
        $index = 2;

        while (CommunityPost::query()
            ->where('slug', $slug)
            ->when($ignoreId, fn ($query) => $query->whereKeyNot($ignoreId))
            ->exists()) {
            $slug = $base.'-'.$index;
            $index++;
        }

        return $slug;
    }
}
