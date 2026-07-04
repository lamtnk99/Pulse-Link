<?php

namespace App\Services\Contracts;

final readonly class AiChatResponse
{
    public function __construct(
        public string $content,
        public string $providerUsed,
        public int $tokensUsed = 0
    ) {}
}
