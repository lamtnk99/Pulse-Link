<!doctype html>
<html lang="vi">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Pulse Link' }}</title>
    <style>
        :root {
            color-scheme: light;
            font-family: Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            color: #172033;
            background: #f7f9fc;
        }
        body { margin: 0; }
        main {
            width: min(920px, calc(100% - 32px));
            margin: 0 auto;
            padding: 48px 0 64px;
        }
        header {
            padding: 28px;
            border: 1px solid #e2e8f0;
            border-radius: 18px;
            background: #ffffff;
            box-shadow: 0 18px 45px rgba(15, 23, 42, .08);
        }
        h1 { margin: 0 0 10px; font-size: clamp(28px, 5vw, 44px); line-height: 1.08; }
        h2 { margin-top: 32px; font-size: 22px; }
        p, li { line-height: 1.72; color: #46556f; }
        a { color: #e11d48; font-weight: 700; text-decoration: none; }
        nav { display: flex; flex-wrap: wrap; gap: 12px; margin: 18px 0 0; }
        nav a {
            padding: 9px 13px;
            border-radius: 999px;
            background: #fff1f2;
            color: #be123c;
        }
        section {
            margin-top: 18px;
            padding: 24px 28px;
            border: 1px solid #e2e8f0;
            border-radius: 16px;
            background: #ffffff;
        }
        .muted { color: #64748b; }
    </style>
</head>
<body>
<main>
    <header>
        <p class="muted">Pulse Link - Mạch Sống</p>
        <h1>{{ $title ?? 'Pulse Link' }}</h1>
        <p>{{ $summary ?? 'Thông tin công khai về quyền riêng tư, điều khoản và hỗ trợ người dùng.' }}</p>
        <nav>
            <a href="{{ route('legal.privacy') }}">Chính sách riêng tư</a>
            <a href="{{ route('legal.terms') }}">Điều khoản</a>
            <a href="{{ route('legal.delete-account') }}">Xóa tài khoản</a>
            <a href="{{ route('support') }}">Hỗ trợ</a>
        </nav>
    </header>

    {{ $slot }}
</main>
</body>
</html>
