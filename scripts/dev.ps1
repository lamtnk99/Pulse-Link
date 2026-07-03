param(
    [string] $ApiBaseUrl = "http://127.0.0.1:8000",
    [string] $FlutterDevice = "chrome",
    [switch] $NoAdmin,
    [switch] $NoMobile
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$backend = Join-Path $root "backend"
$admin = Join-Path $root "admin"

function Require-Command {
    param([string] $Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Missing required command: $Name"
    }
}

Require-Command "php"
Require-Command "npx"

if (-not $NoAdmin) {
    Require-Command "npm"
}

if (-not $NoMobile) {
    Require-Command "flutter"
}

$env:VITE_API_BASE_URL = $ApiBaseUrl

$names = @("api", "reverb")
$colors = @("green", "magenta")
$commands = @(
    "cd `"$backend`" && php artisan serve --host=127.0.0.1 --port=8000",
    "cd `"$backend`" && php artisan reverb:start --host=0.0.0.0 --port=8080"
)

if (-not $NoAdmin) {
    $names += "admin"
    $colors += "cyan"
    $commands += "cd `"$admin`" && npm run dev -- --host 127.0.0.1 --port 5173"
}

if (-not $NoMobile) {
    $names += "mobile"
    $colors += "blue"
    $commands += "cd `"$root`" && flutter run -d $FlutterDevice --dart-define=USE_MOCK_SERVICES=false --dart-define=LARAVEL_API_BASE_URL=$ApiBaseUrl"
}

Write-Host "Pulse Link dev stack" -ForegroundColor Red
Write-Host "API:      $ApiBaseUrl"
Write-Host "Reverb:   ws://127.0.0.1:8080"
if (-not $NoAdmin) { Write-Host "Admin:    http://127.0.0.1:5173" }
if (-not $NoMobile) { Write-Host "Mobile:   flutter device $FlutterDevice" }
Write-Host ""

& npx --yes concurrently `
    --names ($names -join ",") `
    --prefix-colors ($colors -join ",") `
    --kill-others-on-fail `
    --handle-input `
    --default-input-target ($names.Count - 1) `
    @commands
