<?php

namespace App\Services\Contracts;

use App\Models\ChatConversation;

interface AiChatService
{
    public function generateReply(
        ChatConversation $conversation,
        string $userMessage,
        array $healthContext = []
    ): AiChatResponse;
}
