<!doctype html>
<html lang="vi">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $certificate['certificate_id'] }} · Pulse Link</title>
    <style>
        :root {
            --red: #E31837;
            --deep: #54000B;
            --ink: #131722;
            --muted: #667085;
            --gold: #C99A2E;
            --paper: #fffaf3;
        }

        * { box-sizing: border-box; }

        html {
            margin: 0;
        }

        body {
            margin: 0;
            min-height: 100vh;
            display: grid;
            place-items: center;
            padding: 32px;
            background:
                radial-gradient(circle at 12% 16%, rgba(227, 24, 55, .16), transparent 28%),
                radial-gradient(circle at 86% 22%, rgba(201, 154, 46, .16), transparent 24%),
                linear-gradient(135deg, #1b0a0d, #430711 46%, #120608);
            color: var(--ink);
            font-family: "Segoe UI", Arial, "Helvetica Neue", sans-serif;
            -webkit-font-smoothing: antialiased;
            text-rendering: geometricPrecision;
        }

        .wrap { width: min(1160px, 100%); }

        .certificate {
            position: relative;
            overflow: hidden;
            min-height: 650px;
            padding: 34px;
            border-radius: 28px;
            background:
                linear-gradient(135deg, rgba(255,255,255,.96), rgba(255,250,243,.98)),
                var(--paper);
            box-shadow: 0 30px 90px rgba(0, 0, 0, .35);
        }

        .certificate::before {
            content: "";
            position: absolute;
            inset: 20px;
            border: 2px solid rgba(201, 154, 46, .55);
            border-radius: 20px;
            pointer-events: none;
        }

        .certificate::after {
            content: "";
            position: absolute;
            right: -140px;
            top: -170px;
            width: 420px;
            height: 420px;
            border-radius: 50%;
            background: rgba(227, 24, 55, .08);
        }

        .top, .body, .footer { position: relative; z-index: 1; }

        .top {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 24px;
        }

        .brand-logo {
            display: block;
            width: min(300px, 56vw);
            height: auto;
        }

        .code {
            text-align: right;
            color: var(--muted);
            font-size: 13px;
            font-weight: 800;
        }

        .code strong {
            display: block;
            margin-top: 4px;
            color: var(--ink);
            font-size: 16px;
            letter-spacing: .08em;
        }

        .body {
            display: grid;
            grid-template-columns: 1fr 230px;
            gap: 30px;
            margin-top: 38px;
            align-items: center;
        }

        .eyebrow {
            color: var(--red);
            font-size: 13px;
            font-weight: 900;
            letter-spacing: .18em;
            text-transform: uppercase;
        }

        h1 {
            max-width: 720px;
            margin: 12px 0 10px;
            color: var(--deep);
            font-family: "Segoe UI", Arial, "Helvetica Neue", sans-serif;
            font-size: clamp(40px, 5.2vw, 62px);
            font-weight: 900;
            line-height: 1.04;
            letter-spacing: 0;
        }

        .lead {
            max-width: 680px;
            margin: 0;
            color: #475467;
            font-size: 17px;
            line-height: 1.5;
        }

        .name {
            display: inline-block;
            margin: 22px 0 8px;
            padding-bottom: 8px;
            border-bottom: 2px solid rgba(201, 154, 46, .6);
            color: var(--ink);
            font-family: "Segoe UI", Arial, "Helvetica Neue", sans-serif;
            font-size: clamp(30px, 4vw, 46px);
            font-weight: 900;
            line-height: 1.12;
            letter-spacing: 0;
        }

        .seal {
            position: relative;
            display: grid;
            place-items: center;
            width: 198px;
            height: 198px;
            margin-left: auto;
            border-radius: 50%;
            background:
                radial-gradient(circle, #fff 0 48%, transparent 49%),
                conic-gradient(from 6deg, var(--gold), #f3d987, var(--gold), #8c6417, var(--gold));
            box-shadow: 0 22px 50px rgba(84, 0, 11, .15);
        }

        .seal-inner {
            width: 122px;
            height: 122px;
            display: grid;
            place-items: center;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--red), var(--deep));
            color: white;
            text-align: center;
            font-weight: 900;
            box-shadow: inset 0 0 0 8px rgba(255,255,255,.16);
        }

        .seal-inner span {
            display: block;
            margin-top: 4px;
            font-size: 12px;
            letter-spacing: .12em;
        }

        .facts {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 12px;
            margin-top: 30px;
        }

        .fact {
            min-height: 82px;
            padding: 12px;
            border: 1px solid rgba(84, 0, 11, .08);
            border-radius: 16px;
            background: rgba(255,255,255,.72);
        }

        .fact small {
            display: block;
            color: var(--muted);
            font-size: 11px;
            font-weight: 900;
            letter-spacing: .12em;
            text-transform: uppercase;
        }

        .fact strong {
            display: block;
            margin-top: 8px;
            color: var(--ink);
            font-size: 16px;
            line-height: 1.25;
        }

        .footer {
            display: flex;
            justify-content: space-between;
            align-items: flex-end;
            gap: 24px;
            margin-top: 28px;
            color: var(--muted);
            font-size: 13px;
            line-height: 1.5;
        }

        .signature {
            min-width: 260px;
            padding-top: 14px;
            border-top: 1px solid rgba(19, 23, 34, .35);
            text-align: center;
            color: var(--ink);
            font-weight: 900;
        }

        .actions {
            display: flex;
            justify-content: center;
            gap: 12px;
            margin-top: 20px;
        }

        .btn {
            border: 0;
            border-radius: 999px;
            padding: 12px 18px;
            background: white;
            color: var(--deep);
            font-weight: 900;
            text-decoration: none;
            box-shadow: 0 12px 28px rgba(0,0,0,.18);
            cursor: pointer;
        }

        .btn.primary {
            background: var(--red);
            color: white;
        }

        @media (max-width: 820px) {
            body { padding: 14px; }
            .certificate { min-height: 0; padding: 28px; }
            .top, .footer { flex-direction: column; align-items: flex-start; }
            .code { text-align: left; }
            .body { grid-template-columns: 1fr; margin-top: 34px; }
            .seal { width: 168px; height: 168px; margin: 0; }
            .seal-inner { width: 104px; height: 104px; }
            .facts { grid-template-columns: repeat(2, 1fr); }
        }

        @media print {
            @page {
                size: A4 landscape;
                margin: 0;
            }

            html,
            body {
                width: 297mm;
                height: 210mm;
                margin: 0;
                overflow: hidden;
            }

            body {
                display: block;
                padding: 0;
                background: white;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }

            .wrap {
                width: 297mm;
                height: 210mm;
                overflow: hidden;
            }

            .certificate {
                width: 297mm;
                height: 210mm;
                min-height: 0;
                padding: 11mm 13mm;
                border-radius: 0;
                box-shadow: none;
                break-after: avoid;
                page-break-after: avoid;
            }

            .certificate::before {
                inset: 5mm;
                border-radius: 14px;
            }

            .certificate::after {
                right: -28mm;
                top: -34mm;
                width: 88mm;
                height: 88mm;
            }

            .brand-logo { width: 72mm; }
            .code { font-size: 10pt; }
            .code strong { font-size: 12pt; }
            .body {
                grid-template-columns: 1fr 48mm;
                gap: 10mm;
                margin-top: 11mm;
            }
            .eyebrow { font-size: 9pt; }
            h1 {
                max-width: 168mm;
                margin: 4mm 0 3mm;
                font-size: 35pt;
                line-height: 1.04;
            }
            .lead {
                max-width: 160mm;
                font-size: 12pt;
                line-height: 1.38;
            }
            .name {
                margin: 6mm 0 3mm;
                padding-bottom: 2mm;
                font-size: 25pt;
            }
            .seal {
                width: 47mm;
                height: 47mm;
            }
            .seal-inner {
                width: 29mm;
                height: 29mm;
            }
            .facts {
                gap: 3mm;
                margin-top: 9mm;
            }
            .fact {
                min-height: 19mm;
                padding: 3mm;
                border-radius: 10px;
            }
            .fact small { font-size: 7.5pt; }
            .fact strong {
                margin-top: 2mm;
                font-size: 11pt;
                line-height: 1.18;
            }
            .footer {
                margin-top: 8mm;
                font-size: 9pt;
                line-height: 1.35;
            }
            .signature {
                min-width: 52mm;
                padding-top: 3mm;
            }
            .actions { display: none; }
        }
    </style>
</head>
<body>
    <main class="wrap">
        <section class="certificate">
            <div class="top">
                <img class="brand-logo" src="{{ asset('images/pulse_link_logo.png') }}" alt="Pulse Link">
                <div class="code">
                    Mã chứng chỉ
                    <strong>{{ $certificate['certificate_id'] }}</strong>
                </div>
            </div>

            <div class="body">
                <div>
                    <div class="eyebrow">{{ $certificate['verified'] ? 'Đã xác thực' : 'Đang chờ xác thực' }}</div>
                    <h1>Chứng nhận hiến máu</h1>
                    <p class="lead">
                        Pulse Link trân trọng ghi nhận nghĩa cử hiến máu của
                    </p>
                    <div class="name">{{ $certificate['donor_name'] }}</div>
                    <p class="lead">
                        Một lần có mặt đúng lúc có thể trở thành cơ hội sống cho người đang cần máu.
                    </p>
                </div>

                <div class="seal" aria-label="Verified seal">
                    <div class="seal-inner">
                        {{ $certificate['blood_type'] }}
                        <span>{{ $certificate['volume_ml'] }} ml</span>
                    </div>
                </div>
            </div>

            <div class="facts">
                <div class="fact">
                    <small>Ngày hiến</small>
                    <strong>{{ \Illuminate\Support\Carbon::parse($certificate['donated_at'])->format('d/m/Y') }}</strong>
                </div>
                <div class="fact">
                    <small>Loại hiến</small>
                    <strong>{{ $certificate['donation_type'] === 'sos' ? 'Hiến máu SOS' : 'Hiến máu định kỳ' }}</strong>
                </div>
                <div class="fact">
                    <small>Địa điểm</small>
                    <strong>{{ $certificate['location_name'] }}</strong>
                </div>
                <div class="fact">
                    <small>Đơn vị</small>
                    <strong>{{ $certificate['hospital_name'] ?? 'Pulse Link' }}</strong>
                </div>
            </div>

            <div class="footer">
                <div>
                    Trang này xác thực chứng chỉ điện tử do Pulse Link ghi nhận.
                    @if ($certificate['issued_at'])
                        <br>Cấp ngày {{ \Illuminate\Support\Carbon::parse($certificate['issued_at'])->format('d/m/Y') }}.
                    @endif
                    <br>{{ $verifyUrl }}
                </div>
                <div class="signature">Pulse Link</div>
            </div>
        </section>

        <div class="actions">
            <button class="btn primary" onclick="window.print()">In / lưu PDF</button>
            @if (!empty($certificate['blood_journey']))
                <a class="btn" href="{{ url('/journeys/'.$certificate['blood_journey']['public_id']) }}">Theo dõi hành trình</a>
            @endif
            <a class="btn" href="{{ url('/api/certificates/'.$certificate['certificate_id']) }}">Dữ liệu xác thực</a>
        </div>
    </main>
</body>
</html>
