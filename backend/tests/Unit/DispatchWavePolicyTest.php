<?php

namespace Tests\Unit;

use App\Domain\Emergency\DispatchWavePolicy;
use App\Domain\Geo\DistanceCalculator;
use App\Models\Hospital;
use App\Models\User;
use Illuminate\Support\Collection;
use PHPUnit\Framework\TestCase;

class DispatchWavePolicyTest extends TestCase
{
    public function test_it_selects_local_and_inter_province_waves(): void
    {
        $policy = new DispatchWavePolicy(new DistanceCalculator);
        $hospital = new Hospital([
            'province_code' => '79',
            'latitude' => 10.7565,
            'longitude' => 106.6594,
        ]);

        $donors = new Collection([
            new User([
                'name' => 'Local Donor',
                'province_code' => '79',
                'latitude' => 10.7727,
                'longitude' => 106.6663,
            ]),
            new User([
                'name' => 'Inter Province Donor',
                'province_code' => '80',
                'latitude' => 11.3352,
                'longitude' => 106.1099,
            ]),
        ]);

        $result = $policy->selectRecipients($donors, $hospital, 'level3');

        $this->assertCount(2, $result['recipients']);
        $this->assertSame('local5km', $result['recipients'][0]->wave);
        $this->assertSame('inter_province', $result['recipients'][1]->wave);
    }
}
