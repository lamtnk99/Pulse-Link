<?php

namespace Tests\Feature;

use Tests\TestCase;

class LegalPagesTest extends TestCase
{
    public function test_public_legal_and_support_pages_are_accessible(): void
    {
        foreach ([
            '/legal/privacy',
            '/legal/terms',
            '/legal/delete-account',
            '/support',
        ] as $path) {
            $this->get($path)->assertOk();
        }
    }
}
