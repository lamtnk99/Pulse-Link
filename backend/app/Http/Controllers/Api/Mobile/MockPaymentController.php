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
        $method = strtolower($donation->payment_method);

        // Dynamic gateway theming configuration
        $gatewayName = 'CỔNG THANH TOÁN';
        $primaryColor = '#E31837'; // Pulse Link default
        $extraContentHtml = '';

        switch ($method) {
            case 'momo':
                $gatewayName = 'VÍ MOMO SANDBOX';
                $primaryColor = '#A50064'; // MoMo pink
                $extraContentHtml = "
                    <div style='margin: 20px 0; display: flex; flex-direction: column; align-items: center;'>
                        <div style='background: white; padding: 12px; border-radius: 16px; display: inline-block;'>
                            <svg width='130' height='130' viewBox='0 0 100 100' fill='none' xmlns='http://www.w3.org/2000/svg'>
                                <rect width='100' height='100' rx='10' fill='white'/>
                                <rect x='10' y='10' width='25' height='25' fill='#A50064'/>
                                <rect x='15' y='15' width='15' height='15' fill='white'/>
                                <rect x='65' y='10' width='25' height='25' fill='#A50064'/>
                                <rect x='70' y='15' width='15' height='15' fill='white'/>
                                <rect x='10' y='65' width='25' height='25' fill='#A50064'/>
                                <rect x='15' y='70' width='15' height='15' fill='white'/>
                                <rect x='45' y='45' width='10' height='10' fill='#A50064'/>
                                <rect x='40' y='15' width='10' height='20' fill='#A50064'/>
                                <rect x='75' y='45' width='15' height='10' fill='#A50064'/>
                                <rect x='45' y='75' width='20' height='15' fill='#A50064'/>
                            </svg>
                        </div>
                        <span style='font-size: 11px; color: #a5f3fc; margin-top: 8px; font-weight: bold;'>QUÉT MÃ ĐỂ THANH TOÁN THỬ NGHIỆM</span>
                    </div>
                ";
                break;
            case 'zalopay':
                $gatewayName = 'VÍ ZALOPAY SANDBOX';
                $primaryColor = '#008FE5'; // ZaloPay blue
                $extraContentHtml = "
                    <div style='margin: 20px 0; display: flex; flex-direction: column; align-items: center;'>
                        <div style='background: white; padding: 12px; border-radius: 16px; display: inline-block;'>
                            <svg width='130' height='130' viewBox='0 0 100 100' fill='none' xmlns='http://www.w3.org/2000/svg'>
                                <rect width='100' height='100' rx='10' fill='white'/>
                                <rect x='10' y='10' width='25' height='25' fill='#008FE5'/>
                                <rect x='15' y='15' width='15' height='15' fill='white'/>
                                <rect x='65' y='10' width='25' height='25' fill='#008FE5'/>
                                <rect x='70' y='15' width='15' height='15' fill='white'/>
                                <rect x='10' y='65' width='25' height='25' fill='#008FE5'/>
                                <rect x='15' y='70' width='15' height='15' fill='white'/>
                                <rect x='45' y='40' width='15' height='15' fill='#008FE5'/>
                                <rect x='70' y='70' width='15' height='15' fill='#008FE5'/>
                            </svg>
                        </div>
                        <span style='font-size: 11px; color: #a5f3fc; margin-top: 8px; font-weight: bold;'>QUÉT MÃ ĐỂ THANH TOÁN THỬ NGHIỆM</span>
                    </div>
                ";
                break;
            case 'sepay':
                $gatewayName = 'CỔNG THANH TOÁN SEPAY';
                $primaryColor = '#0052cc'; // Banking blue
                $extraContentHtml = "
                    <div style='margin: 18px 0; padding: 16px; background: rgba(255, 255, 255, 0.03); border-radius: 16px; border: 1px dashed rgba(255, 255, 255, 0.15); text-align: left;'>
                        <div style='font-size: 12px; color: #94a3b8; font-weight: bold; margin-bottom: 12px; text-align: center; letter-spacing: 0.5px;'>THÔNG TIN CHUYỂN KHOẢN NHANH (MOCK VIETQR)</div>
                        <div style='display: flex; justify-content: space-between; margin-bottom: 6px; font-size: 13.5px;'>
                            <span style='color: #94a3b8;'>Ngân hàng:</span>
                            <span style='font-weight: bold; color: #ffffff;'>MB Bank</span>
                        </div>
                        <div style='display: flex; justify-content: space-between; margin-bottom: 6px; font-size: 13.5px;'>
                            <span style='color: #94a3b8;'>Chủ tài khoản:</span>
                            <span style='font-weight: bold; color: #ffffff;'>QUY NHAN AI PULSE LINK</span>
                        </div>
                        <div style='display: flex; justify-content: space-between; margin-bottom: 6px; font-size: 13.5px;'>
                            <span style='color: #94a3b8;'>Số tài khoản:</span>
                            <span style='font-weight: bold; color: #38bdf8;'>9999888882222</span>
                        </div>
                        <div style='display: flex; justify-content: space-between; margin-bottom: 6px; font-size: 13.5px;'>
                            <span style='color: #94a3b8;'>Nội dung:</span>
                            <span style='font-weight: bold; color: #f59e0b;'>PL {$donation->transaction_id}</span>
                        </div>
                        <div style='margin-top: 14px; text-align: center;'>
                            <div style='background: white; padding: 8px; border-radius: 12px; display: inline-block;'>
                                <svg width='110' height='110' viewBox='0 0 100 100' fill='none' xmlns='http://www.w3.org/2000/svg'>
                                    <rect width='100' height='100' rx='10' fill='white'/>
                                    <rect x='10' y='10' width='25' height='25' fill='#0052cc'/>
                                    <rect x='15' y='15' width='15' height='15' fill='white'/>
                                    <rect x='65' y='10' width='25' height='25' fill='#0052cc'/>
                                    <rect x='70' y='15' width='15' height='15' fill='white'/>
                                    <rect x='10' y='65' width='25' height='25' fill='#0052cc'/>
                                    <rect x='15' y='70' width='15' height='15' fill='white'/>
                                    <rect x='40' y='40' width='20' height='20' fill='#0052cc'/>
                                    <rect x='45' y='45' width='10' height='10' fill='white'/>
                                </svg>
                            </div>
                            <div style='font-size: 10px; color: #34d399; margin-top: 6px; font-weight: bold;'>SEPAY WEBHOOK SẼ TỰ ĐỘNG XÁC NHẬN KHI BẤM NÚT DƯỚI</div>
                        </div>
                    </div>
                ";
                break;
            case 'vnpay':
                $gatewayName = 'CỔNG THANH TOÁN VNPAY SANDBOX';
                $primaryColor = '#005baa'; // VNPay blue
                $extraContentHtml = "
                    <div style='margin: 18px 0; padding: 14px; background: rgba(255, 255, 255, 0.03); border-radius: 16px; border: 1px solid rgba(255, 255, 255, 0.08); text-align: left;'>
                        <div style='font-size: 12px; color: #94a3b8; font-weight: bold; margin-bottom: 8px; text-align: center;'>THẺ THỬ NGHIỆM ĐƯỢC CẤP (NCB)</div>
                        <div style='font-size: 13px; color: #ffffff; line-height: 1.6;'>
                            • Ngân hàng: <span style='font-weight: bold;'>NCB (Ngân hàng Quốc Dân)</span><br>
                            • Số thẻ ATM: <span style='font-weight: bold; color: #38bdf8;'>9704198526191432198</span><br>
                            • Tên chủ thẻ: <span style='font-weight: bold;'>NGUYEN VAN A</span><br>
                            • OTP xác nhận: <span style='font-weight: bold; color: #f59e0b;'>123456</span>
                        </div>
                    </div>
                ";
                break;
            default:
                $gatewayName = 'CỔNG THANH TOÁN GIẢ LẬP';
                break;
        }

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
            background: rgba(255, 255, 255, 0.04);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 24px;
            padding: 28px 24px;
            width: 90%;
            max-width: 400px;
            text-align: center;
            box-shadow: 0 12px 40px 0 rgba(0, 0, 0, 0.5);
        }
        .logo {
            font-size: 26px;
            font-weight: 900;
            color: {$primaryColor};
            margin-bottom: 6px;
            letter-spacing: 1.5px;
            text-shadow: 0 0 12px rgba(255, 255, 255, 0.05);
        }
        .subtitle {
            font-size: 11px;
            color: #94a3b8;
            margin-bottom: 20px;
            font-weight: bold;
            letter-spacing: 1px;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            margin: 10px 0;
            font-size: 13.5px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.05);
            padding-bottom: 8px;
        }
        .detail-label {
            color: #94a3b8;
        }
        .detail-value {
            font-weight: bold;
            color: #f8fafc;
        }
        .amount {
            font-size: 30px;
            font-weight: 900;
            color: #10b981;
            margin: 18px 0;
            text-shadow: 0 0 10px rgba(16, 185, 129, 0.25);
        }
        .btn {
            display: block;
            width: 100%;
            padding: 14px;
            border: none;
            border-radius: 14px;
            font-size: 14px;
            font-weight: 900;
            cursor: pointer;
            margin-top: 12px;
            transition: all 0.2s;
        }
        .btn-success {
            background-color: {$primaryColor};
            color: white;
            box-shadow: 0 4px 14px rgba(227, 24, 55, 0.2);
        }
        .btn-success:hover {
            opacity: 0.95;
            transform: translateY(-1px);
        }
        .btn-cancel {
            background-color: transparent;
            border: 1px solid rgba(255, 255, 255, 0.15);
            color: #94a3b8;
        }
        .btn-cancel:hover {
            background: rgba(255, 255, 255, 0.02);
            color: #cbd5e1;
        }
    </style>
</head>
<body>
    <div class='card'>
        <div class='logo'>PULSE LINK</div>
        <div class='subtitle'>{$gatewayName}</div>
        
        <div class='detail-row'>
            <span class='detail-label'>Chiến dịch:</span>
            <span class='detail-value'>{$donation->campaign->title}</span>
        </div>
        <div class='detail-row'>
            <span class='detail-label'>Mã giao dịch:</span>
            <span class='detail-value'>{$donation->transaction_id}</span>
        </div>
        <div class='detail-row'>
            <span class='detail-label'>Cổng thanh toán:</span>
            <span class='detail-value' style='text-transform: uppercase;'>{$method}</span>
        </div>

        {$extraContentHtml}

        <div class='amount'>{$amountFormatted}</div>

        <form action='" . route('mock-payment.submit') . "' method='POST'>
            <input type='hidden' name='transaction_id' value='{$donation->transaction_id}'>
            <button type='submit' name='status' value='success' class='btn btn-success'>XÁC NHẬN THANH TOÁN (DEMO)</button>
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
