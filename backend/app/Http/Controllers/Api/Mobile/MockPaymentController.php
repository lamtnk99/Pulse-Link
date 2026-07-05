<?php

namespace App\Http\Controllers\Api\Mobile;

use App\Http\Controllers\Controller;
use App\Models\CampaignDonation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class MockPaymentController extends Controller
{
    public function show($transactionId)
    {
        $donation = CampaignDonation::query()
            ->where('transaction_id', $transactionId)
            ->with('campaign')
            ->firstOrFail();

        $amountFormatted = number_format($donation->amount) . ' VND';

        // Return a beautiful payment simulator page
        return response("
<!DOCTYPE html>
<html lang='vi'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Cổng Thanh Toán Giả Lập - Pulse Link</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: #0b1329;
            color: #ffffff;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .card {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(16px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 24px;
            padding: 32px;
            width: 90%;
            max-width: 400px;
            text-align: center;
            box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
        }
        .logo {
            font-size: 24px;
            font-weight: 900;
            color: #E31837;
            margin-bottom: 8px;
            letter-spacing: 1px;
        }
        .subtitle {
            font-size: 13px;
            color: #94a3b8;
            margin-bottom: 24px;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            margin: 12px 0;
            font-size: 14px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
            padding-bottom: 8px;
        }
        .detail-label {
            color: #94a3b8;
        }
        .detail-value {
            font-weight: bold;
        }
        .amount {
            font-size: 28px;
            font-weight: 900;
            color: #10b981;
            margin: 20px 0;
        }
        .btn {
            display: block;
            width: 100%;
            padding: 14px;
            border: none;
            border-radius: 12px;
            font-size: 14px;
            font-weight: bold;
            cursor: pointer;
            margin-top: 12px;
            transition: transform 0.1s;
        }
        .btn:active {
            transform: scale(0.98);
        }
        .btn-success {
            background-color: #E31837;
            color: white;
            box-shadow: 0 4px 14px rgba(227, 24, 55, 0.4);
        }
        .btn-cancel {
            background-color: transparent;
            border: 1px solid rgba(255, 255, 255, 0.2);
            color: #94a3b8;
        }
    </style>
</head>
<body>
    <div class='card'>
        <div class='logo'>PULSE LINK</div>
        <div class='subtitle'>CỔNG THANH TOÁN GIẢ LẬP</div>
        
        <div class='detail-row'>
            <span class='detail-label'>Chiến dịch:</span>
            <span class='detail-value'>{$donation->campaign->title}</span>
        </div>
        <div class='detail-row'>
            <span class='detail-label'>Mã giao dịch:</span>
            <span class='detail-value'>{$donation->transaction_id}</span>
        </div>
        <div class='detail-row'>
            <span class='detail-label'>Phương thức:</span>
            <span class='detail-value'>{$donation->payment_method}</span>
        </div>

        <div class='amount'>{$amountFormatted}</div>

        <form action='" . route('mock-payment.submit') . "' method='POST'>
            <input type='hidden' name='transaction_id' value='{$donation->transaction_id}'>
            <button type='submit' name='status' value='success' class='btn btn-success'>XÁC NHẬN THANH TOÁN</button>
            <button type='submit' name='status' value='failed' class='btn btn-cancel'>HỦY GIAO DỊCH</button>
        </form>
    </div>
</body>
</html>
        ")->header('Content-Type', 'text/html');
    }

    public function submit(Request $request)
    {
        $payload = $request->validate([
            'transaction_id' => ['required', 'string'],
            'status' => ['required', 'string', 'in:success,failed'],
        ]);

        // Send a internal POST request to the webhook endpoint
        $response = Http::post(route('payment.webhook'), [
            'transaction_id' => $payload['transaction_id'],
            'status' => $payload['status'],
        ]);

        $statusMessage = $payload['status'] === 'success' 
            ? 'Thanh toán thành công!' 
            : 'Thanh toán đã bị hủy.';
        
        $color = $payload['status'] === 'success' ? '#10b981' : '#ef4444';

        // Return result page
        return response("
<!DOCTYPE html>
<html lang='vi'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Kết quả thanh toán</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: #0b1329;
            color: #ffffff;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .card {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(16px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 24px;
            padding: 32px;
            width: 90%;
            max-width: 400px;
            text-align: center;
            box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
        }
        .status {
            font-size: 24px;
            font-weight: bold;
            color: {$color};
            margin-bottom: 16px;
        }
        .msg {
            color: #94a3b8;
            font-size: 14px;
            margin-bottom: 24px;
        }
        .btn {
            display: inline-block;
            background-color: #E31837;
            color: white;
            padding: 12px 24px;
            border-radius: 12px;
            text-decoration: none;
            font-weight: bold;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class='card'>
        <div class='status'>{$statusMessage}</div>
        <div class='msg'>Giao dịch {$payload['transaction_id']} đã được xử lý. Bạn có thể quay về ứng dụng Pulse Link.</div>
        <a href='#' onclick='window.close();' class='btn'>ĐÓNG CỬA SỔ</a>
    </div>
</body>
</html>
        ")->header('Content-Type', 'text/html');
    }
}
