<!doctype html>
<html lang="vi">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="theme-color" content="#f8fafc">
    <title>{{ $title ?? 'Pulse Link' }}</title>
    <style>
        :root {
            color-scheme: light;
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            color: #172033;
            background: #f8fafc;
            --ink: #172033;
            --muted: #60708a;
            --line: #dfe6ef;
            --rose: #e82046;
            --rose-dark: #bd1638;
            --rose-soft: #fff0f3;
            --mint: #e8f6ee;
            --surface: #ffffff;
        }

        * { box-sizing: border-box; }
        body { margin: 0; background: #f8fafc; }
        a { color: inherit; }

        .site-header {
            border-bottom: 1px solid var(--line);
            background: rgba(255, 255, 255, .96);
        }

        .site-header__inner,
        main,
        .site-footer__inner {
            width: min(1080px, calc(100% - 40px));
            margin: 0 auto;
        }

        .site-header__inner {
            min-height: 68px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 24px;
        }

        .brand {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            color: var(--ink);
            font-weight: 850;
            text-decoration: none;
        }

        .brand-mark {
            width: 30px;
            height: 30px;
            display: grid;
            place-items: center;
            border-radius: 8px;
            background: var(--rose);
            color: #fff;
            font-size: 15px;
            line-height: 1;
        }

        .brand small {
            display: block;
            margin-top: 1px;
            color: var(--muted);
            font-size: 11px;
            font-weight: 650;
        }

        .header-note {
            color: var(--muted);
            font-size: 13px;
            font-weight: 650;
        }

        .hero {
            padding: 48px 0 32px;
            border-bottom: 1px solid var(--line);
            background: var(--surface);
        }

        .hero__content {
            width: min(1080px, calc(100% - 40px));
            margin: 0 auto;
            display: grid;
            grid-template-columns: minmax(0, 1fr) 220px;
            gap: 40px;
            align-items: end;
        }

        .eyebrow {
            margin: 0 0 12px;
            color: var(--rose);
            font-size: 12px;
            font-weight: 850;
            letter-spacing: .08em;
            text-transform: uppercase;
        }

        h1 {
            max-width: 760px;
            margin: 0;
            color: var(--ink);
            font-size: clamp(32px, 5vw, 54px);
            line-height: 1.04;
            letter-spacing: 0;
        }

        .hero__summary {
            max-width: 700px;
            margin: 16px 0 0;
            color: var(--muted);
            font-size: 17px;
            line-height: 1.6;
        }

        .hero__stamp {
            padding: 18px;
            border: 1px solid #f4c7d1;
            border-radius: 8px;
            background: var(--rose-soft);
        }

        .hero__stamp strong,
        .hero__stamp span { display: block; }
        .hero__stamp strong { color: var(--rose-dark); font-size: 14px; }
        .hero__stamp span { margin-top: 6px; color: #8d3347; font-size: 13px; line-height: 1.45; }

        .legal-nav {
            width: min(1080px, calc(100% - 40px));
            margin: 0 auto;
            display: flex;
            gap: 4px;
            overflow-x: auto;
            padding: 14px 0;
        }

        .legal-nav a {
            flex: 0 0 auto;
            padding: 9px 12px;
            border-radius: 7px;
            color: #4a5970;
            font-size: 13px;
            font-weight: 760;
            text-decoration: none;
        }

        .legal-nav a:hover,
        .legal-nav a[aria-current="page"] { background: var(--rose-soft); color: var(--rose-dark); }

        main { padding: 40px 0 56px; }
        .legal-content { width: min(760px, 100%); }
        .legal-content section {
            padding: 0 0 30px;
            margin: 0 0 30px;
            border-bottom: 1px solid var(--line);
        }

        .legal-content section:last-child { margin-bottom: 0; }
        .legal-content h2 { margin: 0 0 12px; color: var(--ink); font-size: 21px; line-height: 1.25; }
        .legal-content p,
        .legal-content li { color: #465670; font-size: 16px; line-height: 1.72; }
        .legal-content p { margin: 0; }
        .legal-content p + p { margin-top: 12px; }
        .legal-content ul,
        .legal-content ol { margin: 0; padding-left: 22px; }
        .legal-content li + li { margin-top: 8px; }
        .legal-content li::marker { color: var(--rose); font-weight: 800; }
        .legal-content a { color: var(--rose-dark); font-weight: 800; text-decoration-thickness: 1px; text-underline-offset: 3px; }

        .legal-callout {
            margin: 0 0 30px;
            padding: 16px 18px;
            border-left: 4px solid #2d9b65;
            background: var(--mint);
            color: #24573b;
            font-size: 14px;
            font-weight: 650;
            line-height: 1.55;
        }

        .site-footer { border-top: 1px solid var(--line); background: #fff; }
        .site-footer__inner {
            display: flex;
            justify-content: space-between;
            gap: 18px;
            padding: 24px 0;
            color: var(--muted);
            font-size: 13px;
            line-height: 1.5;
        }

        @media (max-width: 700px) {
            .site-header__inner,
            main,
            .site-footer__inner,
            .hero__content,
            .legal-nav { width: min(100% - 28px, 1080px); }
            .site-header__inner { min-height: 60px; }
            .header-note { display: none; }
            .hero { padding: 32px 0 22px; }
            .hero__content { display: block; }
            .hero__summary { margin-top: 12px; font-size: 16px; }
            .hero__stamp { display: none; }
            .legal-nav { padding: 10px 0; }
            main { padding: 28px 0 42px; }
            .legal-content section { padding-bottom: 24px; margin-bottom: 24px; }
            .legal-content h2 { font-size: 19px; }
            .legal-content p, .legal-content li { font-size: 15px; line-height: 1.65; }
            .site-footer__inner { display: block; padding: 20px 0; }
            .site-footer__inner span + span { display: block; margin-top: 4px; }
        }
    </style>
</head>
<body>
<header class="site-header">
    <div class="site-header__inner">
        <a class="brand" href="{{ route('legal.privacy') }}" aria-label="Pulse Link - Trung tâm quyền riêng tư">
            <span class="brand-mark" aria-hidden="true">+</span>
            <span>Pulse Link<small>Mạch Sống</small></span>
        </a>
        <span class="header-note">Trung tâm quyền riêng tư</span>
    </div>
</header>

<section class="hero">
    <div class="hero__content">
        <div>
            <p class="eyebrow">Pulse Link · Mạch Sống</p>
            <h1>{{ $title ?? 'Pulse Link' }}</h1>
            <p class="hero__summary">{{ $summary ?? 'Thông tin công khai về quyền riêng tư, điều khoản và hỗ trợ người dùng.' }}</p>
        </div>
        <aside class="hero__stamp" aria-label="Cam kết của Pulse Link">
            <strong>Dữ liệu vì sự sống</strong>
            <span>Rõ ràng trong điều phối, tôn trọng quyền riêng tư.</span>
        </aside>
    </div>
</section>

<nav class="legal-nav" aria-label="Điều hướng pháp lý">
    <a href="{{ route('legal.privacy') }}" @if(request()->routeIs('legal.privacy')) aria-current="page" @endif>Quyền riêng tư</a>
    <a href="{{ route('legal.terms') }}" @if(request()->routeIs('legal.terms')) aria-current="page" @endif>Điều khoản</a>
    <a href="{{ route('legal.delete-account') }}" @if(request()->routeIs('legal.delete-account')) aria-current="page" @endif>Xóa tài khoản</a>
    <a href="{{ route('support') }}" @if(request()->routeIs('support')) aria-current="page" @endif>Hỗ trợ</a>
</nav>

<main>
    <article class="legal-content">
        {{ $slot }}
    </article>
</main>

<footer class="site-footer">
    <div class="site-footer__inner">
        <span>Pulse Link · Mạch Sống</span>
        <span>Cập nhật ngày 10 tháng 7 năm 2026</span>
    </div>
</footer>
</body>
</html>
