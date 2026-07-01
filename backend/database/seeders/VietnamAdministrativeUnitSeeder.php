<?php

namespace Database\Seeders;

use App\Models\AdministrativeUnit;
use App\Models\Province;
use App\Models\Ward;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class VietnamAdministrativeUnitSeeder extends Seeder
{
    private const DATASET_PATH = __DIR__.'/../data/vietnam-administrative-units/full_json_generated_data_vn_units.json';

    public function run(): void
    {
        $items = json_decode(file_get_contents(self::DATASET_PATH), true, flags: JSON_THROW_ON_ERROR);
        $now = now();

        $units = [];
        $provinces = [];
        $wards = [];

        foreach ($items as $province) {
            $units[$province['AdministrativeUnitId']] = [
                'id' => $province['AdministrativeUnitId'],
                'short_name' => $province['AdministrativeUnitShortName'],
                'full_name' => $province['AdministrativeUnitFullName'],
                'short_name_en' => $province['AdministrativeUnitShortNameEn'] ?? null,
                'full_name_en' => $province['AdministrativeUnitFullNameEn'] ?? null,
                'created_at' => $now,
                'updated_at' => $now,
            ];

            $provinces[] = [
                'code' => $province['Code'],
                'name' => $province['Name'],
                'name_en' => $province['NameEn'] ?? null,
                'full_name' => $province['FullName'],
                'full_name_en' => $province['FullNameEn'] ?? null,
                'code_name' => $province['CodeName'],
                'administrative_unit_id' => $province['AdministrativeUnitId'],
                'region_code' => null,
                'centroid_latitude' => $this->centroid($province['Code'])[0] ?? null,
                'centroid_longitude' => $this->centroid($province['Code'])[1] ?? null,
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ];

            foreach ($province['Wards'] as $ward) {
                $units[$ward['AdministrativeUnitId']] = [
                    'id' => $ward['AdministrativeUnitId'],
                    'short_name' => $ward['AdministrativeUnitShortName'],
                    'full_name' => $ward['AdministrativeUnitFullName'],
                    'short_name_en' => $ward['AdministrativeUnitShortNameEn'] ?? null,
                    'full_name_en' => $ward['AdministrativeUnitFullNameEn'] ?? null,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];

                $wards[] = [
                    'code' => $ward['Code'],
                    'province_code' => $ward['ProvinceCode'],
                    'name' => $ward['Name'],
                    'name_en' => $ward['NameEn'] ?? null,
                    'full_name' => $ward['FullName'],
                    'full_name_en' => $ward['FullNameEn'] ?? null,
                    'code_name' => $ward['CodeName'],
                    'administrative_unit_id' => $ward['AdministrativeUnitId'],
                    'is_active' => true,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }
        }

        DB::transaction(function () use ($units, $provinces, $wards): void {
            AdministrativeUnit::query()->upsert(
                array_values($units),
                ['id'],
                ['short_name', 'full_name', 'short_name_en', 'full_name_en', 'updated_at'],
            );

            Province::query()->upsert(
                $provinces,
                ['code'],
                ['name', 'name_en', 'full_name', 'full_name_en', 'code_name', 'administrative_unit_id', 'region_code', 'centroid_latitude', 'centroid_longitude', 'is_active', 'updated_at'],
            );

            foreach (array_chunk($wards, 500) as $chunk) {
                Ward::query()->upsert(
                    $chunk,
                    ['code'],
                    ['province_code', 'name', 'name_en', 'full_name', 'full_name_en', 'code_name', 'administrative_unit_id', 'is_active', 'updated_at'],
                );
            }
        });
    }

    private function centroid(string $code): array
    {
        return [
            '01' => [21.0285, 105.8542],
            '04' => [22.6657, 106.2570],
            '08' => [21.8236, 105.2142],
            '11' => [21.3860, 103.0169],
            '12' => [22.3862, 103.4707],
            '14' => [21.3256, 103.9188],
            '15' => [22.4809, 103.9755],
            '19' => [21.5942, 105.8482],
            '20' => [21.8537, 106.7615],
            '22' => [20.9712, 107.0448],
            '24' => [21.1861, 106.0763],
            '25' => [21.3227, 105.4017],
            '31' => [20.8449, 106.6881],
            '33' => [20.6464, 106.0511],
            '37' => [20.2506, 105.9745],
            '38' => [19.8075, 105.7763],
            '40' => [18.6796, 105.6813],
            '42' => [18.3559, 105.8877],
            '44' => [16.7500, 107.1900],
            '46' => [16.4637, 107.5909],
            '48' => [16.0471, 108.2068],
            '51' => [15.1214, 108.8044],
            '52' => [13.9833, 108.0000],
            '56' => [12.2388, 109.1967],
            '66' => [12.6667, 108.0500],
            '68' => [11.5753, 108.1429],
            '75' => [10.9574, 106.8427],
            '79' => [10.7769, 106.7009],
            '80' => [11.3352, 106.1099],
            '82' => [10.4938, 105.6882],
            '86' => [10.2537, 105.9722],
            '91' => [10.5216, 105.1259],
            '92' => [10.0452, 105.7469],
            '96' => [9.1768, 105.1524],
        ][$code] ?? [];
    }
}
