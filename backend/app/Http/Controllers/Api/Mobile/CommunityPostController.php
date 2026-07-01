<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Http\Resources\CommunityPostResource;
use App\Models\CommunityPost;
use App\Services\Mobile\MobileUserResolver;
use Illuminate\Http\Request;

class CommunityPostController extends Controller
{
    public function __construct(
        private readonly MobileUserResolver $mobileUserResolver,
    ) {}

    public function index(Request $request)
    {
        $user = $this->mobileUserResolver->resolve($request->integer('user_id'));

        return CommunityPostResource::collection(
            CommunityPost::query()
                ->with('province', 'ward', 'hospital.province', 'hospital.ward')
                ->where('status', 'published')
                ->whereNotNull('published_at')
                ->where('published_at', '<=', now())
                ->where(function ($query) use ($user): void {
                    $query
                        ->where('audience_type', 'all')
                        ->orWhere(function ($query) use ($user): void {
                            $query
                                ->where('audience_type', 'province')
                                ->where('province_code', $user->province_code);
                        })
                        ->orWhere(function ($query) use ($user): void {
                            $query
                                ->where('audience_type', 'blood_type')
                                ->where('target_blood_type', $user->blood_type);
                        })
                        ->orWhere(function ($query) use ($user): void {
                            $query
                                ->where('audience_type', 'hero_level')
                                ->where('target_hero_level', $user->hero_level);
                        });
                })
                ->latest('published_at')
                ->get()
        );
    }

    public function show(Request $request, CommunityPost $post): CommunityPostResource
    {
        abort_unless($post->status === 'published' && $post->published_at?->isPast(), 404);

        $post->increment('views_count');

        return CommunityPostResource::make(
            $post->refresh()->load('province', 'ward', 'hospital.province', 'hospital.ward')
        );
    }
}
