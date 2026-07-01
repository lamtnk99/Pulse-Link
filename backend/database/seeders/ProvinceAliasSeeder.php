<?php

namespace Database\Seeders;

use App\Models\Province;
use App\Models\ProvinceAlias;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class ProvinceAliasSeeder extends Seeder
{
    public function run(): void
    {
        $aliases = [
            ['TP.HCM', '79', 'Common abbreviation'],
            ['HCM', '79', 'Legacy seed code'],
            ['Sai Gon', '79', 'Historic/common name'],
            ['Sài Gòn', '79', 'Historic/common name'],
            ['Binh Duong', '79', 'Former province merged into Ho Chi Minh City area in current demo taxonomy'],
            ['Bình Dương', '79', 'Former province merged into Ho Chi Minh City area in current demo taxonomy'],
            ['Ba Ria - Vung Tau', '79', 'Former province merged into Ho Chi Minh City area in current demo taxonomy'],
            ['Bà Rịa - Vũng Tàu', '79', 'Former province merged into Ho Chi Minh City area in current demo taxonomy'],
            ['Long An', '80', 'Former province mapped to current Tay Ninh area in current demo taxonomy'],
            ['LA', '80', 'Legacy seed code'],
            ['Dong Nai', '75', 'ASCII alias'],
            ['Đồng Nai', '75', 'Vietnamese alias'],
            ['Da Nang', '48', 'ASCII alias'],
            ['Đà Nẵng', '48', 'Vietnamese alias'],
            ['Can Tho', '92', 'ASCII alias'],
            ['Cần Thơ', '92', 'Vietnamese alias'],
            ['Ha Noi', '01', 'ASCII alias'],
            ['Hà Nội', '01', 'Vietnamese alias'],
        ];

        foreach ($aliases as [$alias, $provinceCode, $note]) {
            if (! Province::query()->whereKey($provinceCode)->exists()) {
                continue;
            }

            ProvinceAlias::query()->updateOrCreate(
                ['alias' => $alias],
                [
                    'normalized_alias' => $this->normalize($alias),
                    'province_code' => $provinceCode,
                    'note' => $note,
                ],
            );
        }
    }

    private function normalize(string $value): string
    {
        return Str::of($value)
            ->ascii()
            ->lower()
            ->replaceMatches('/[^a-z0-9]+/', '_')
            ->trim('_')
            ->toString();
    }
}
