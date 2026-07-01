<?php

namespace App\Repositories\Contracts;

use Illuminate\Support\Collection;

interface DonorRepository
{
    public function compatibleActiveDonors(array $bloodTypes): Collection;
}
