<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DonationHistory;
use Illuminate\Http\JsonResponse;
use Illuminate\View\View;

class CertificateController extends Controller
{
    public function show(string $certificateId): JsonResponse
    {
        return response()->json(['data' => $this->payload($this->findCertificate($certificateId))]);
    }

    public function page(string $certificateId): View
    {
        $history = $this->findCertificate($certificateId);

        return view('certificates.show', [
            'certificate' => $this->payload($history),
            'verifyUrl' => url('/certificates/'.$history->certificate_id),
        ]);
    }

    private function findCertificate(string $certificateId): DonationHistory
    {
        return DonationHistory::query()
            ->with('user', 'hospital')
            ->where('certificate_id', $certificateId)
            ->firstOrFail();
    }

    private function payload(DonationHistory $history): array
    {
        return [
            'certificate_id' => $history->certificate_id,
            'certificate_title' => $history->certificate_title,
            'status' => $history->status,
            'donor_name' => $history->user?->name ?? 'Người hiến máu',
            'blood_type' => $history->blood_type,
            'donated_at' => $history->donated_at?->toIso8601String(),
            'volume_ml' => $history->volume_ml,
            'donation_type' => $history->donation_type ?? 'regular',
            'location_name' => $history->location_name,
            'hospital_name' => $history->hospital?->name,
            'issued_at' => $history->certificate_issued_at?->toIso8601String(),
            'verified' => $history->status === 'verified',
        ];
    }
}
