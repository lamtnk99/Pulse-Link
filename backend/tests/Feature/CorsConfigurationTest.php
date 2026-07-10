<?php

namespace Tests\Feature;

use Tests\TestCase;

class CorsConfigurationTest extends TestCase
{
    public function test_admin_origin_is_allowed_to_preflight_api_requests(): void
    {
        $response = $this->call('OPTIONS', '/api/admin/emergency-alerts', [], [], [], [
            'HTTP_ORIGIN' => 'https://admin.pulselink.asia',
            'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST',
            'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' => 'Authorization, Content-Type',
        ]);

        $response
            ->assertNoContent()
            ->assertHeader('Access-Control-Allow-Origin', 'https://admin.pulselink.asia');
    }
}
