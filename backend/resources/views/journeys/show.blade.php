<!doctype html>
<html lang="vi">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Hành trình giọt máu · Pulse Link</title>
    <style>
        :root { --red: #E31837; --deep: #54000B; --ink: #111827; --muted: #667085; }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            min-height: 100vh;
            padding: 28px;
            background: linear-gradient(135deg, #fff7f7, #f8fafc 58%, #fffaf3);
            color: var(--ink);
            font-family: "Segoe UI", Arial, sans-serif;
        }
        .wrap { width: min(860px, 100%); margin: 0 auto; }
        .hero {
            padding: 28px;
            border: 1px solid rgba(227, 24, 55, .14);
            border-radius: 24px;
            background: white;
            box-shadow: 0 20px 60px rgba(15, 23, 42, .08);
        }
        .eyebrow { color: var(--red); font-size: 12px; font-weight: 900; letter-spacing: .16em; text-transform: uppercase; }
        h1 { margin: 10px 0 8px; color: var(--deep); font-size: clamp(34px, 7vw, 58px); line-height: 1; }
        p { color: #475467; line-height: 1.6; }
        .steps { margin-top: 20px; display: grid; gap: 12px; }
        .step {
            display: grid;
            grid-template-columns: 40px 1fr;
            gap: 12px;
            align-items: start;
            padding: 14px;
            border-radius: 16px;
            background: #f8fafc;
            border: 1px solid #e5e7eb;
        }
        .dot {
            display: grid;
            place-items: center;
            width: 40px;
            height: 40px;
            border-radius: 999px;
            background: #e5e7eb;
            color: #64748b;
            font-weight: 900;
        }
        .step.done { background: #fff7f7; border-color: rgba(227, 24, 55, .16); }
        .step.done .dot { background: var(--red); color: white; }
        .step strong { display: block; margin-top: 2px; }
        .step small { color: var(--muted); font-weight: 700; }
        .message {
            margin-top: 20px;
            padding: 18px;
            border-radius: 18px;
            background: #fff1f2;
            color: var(--deep);
            font-weight: 800;
        }
        .meta { margin-top: 18px; color: var(--muted); font-size: 13px; font-weight: 700; }
    </style>
</head>
<body>
    <main class="wrap">
        <section class="hero">
            <div class="eyebrow">Pulse Link · Hành trình giọt máu</div>
            <h1>Một phần sự sống đang được tiếp nối</h1>
            <p>
                Hệ thống chỉ hiển thị tiến trình tổng quan để bảo vệ riêng tư của người bệnh và người hiến.
            </p>

            <div class="steps">
                @foreach ($journey['steps'] as $index => $step)
                    <div class="step {{ $step['completed'] ? 'done' : '' }}">
                        <div class="dot">{{ $step['completed'] ? '✓' : $index + 1 }}</div>
                        <div>
                            <strong>{{ $step['label'] }}</strong>
                            @if ($step['occurred_at'])
                                <small>{{ \Illuminate\Support\Carbon::parse($step['occurred_at'])->timezone('Asia/Ho_Chi_Minh')->format('H:i d/m/Y') }}</small>
                            @endif
                        </div>
                    </div>
                @endforeach
            </div>

            @if (! empty($journey['published_at']) && ! empty($journey['final_message']))
                <div class="message">{{ $journey['final_message'] }}</div>
            @else
                <div class="message">Bệnh viện đang cập nhật hành trình giọt máu của bạn.</div>
            @endif

            <div class="meta">
                {{ $journey['hospital']['name'] ?? 'Bệnh viện tiếp nhận' }}
                @if (! empty($journey['location_label']))
                    · {{ $journey['location_label'] }}
                @endif
            </div>
        </section>
    </main>
</body>
</html>
