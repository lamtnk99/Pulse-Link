<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => array_values(array_filter(array_map(
        'trim',
        explode(',', (string) env(
            'CORS_ALLOWED_ORIGINS',
            'https://admin.pulselink.asia,https://pulselink.asia,https://www.pulselink.asia,http://localhost:5173,http://127.0.0.1:5173'
        ))
    ))),

    // Flutter Web uses a random localhost port in debug mode. Keep the
    // explicit production allow-list above and permit only loopback origins
    // for local development, regardless of the generated debug port.
    'allowed_origins_patterns' => [
        '#^https?://(localhost|127\\.0\\.0\\.1)(:\\d+)?$#',
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,
];
