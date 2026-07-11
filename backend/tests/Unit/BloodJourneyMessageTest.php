<?php

namespace Tests\Unit;

use App\Models\BloodJourney;
use PHPUnit\Framework\TestCase;

class BloodJourneyMessageTest extends TestCase
{
    public function test_it_rejects_a_truncated_gratitude_message(): void
    {
        $this->assertFalse(BloodJourney::hasCompleteFinalMessage('Anh Trần Minh Quân ơi, cả nhà em'));
    }

    public function test_generated_fallback_messages_are_complete(): void
    {
        $this->assertTrue(BloodJourney::hasCompleteFinalMessage(
            BloodJourney::finalMessageFor('patient', 1)
        ));
        $this->assertTrue(BloodJourney::hasCompleteFinalMessage(
            BloodJourney::finalMessageFor('reserve', 1)
        ));
    }
}
