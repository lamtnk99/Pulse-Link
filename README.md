# Pulse Link Flutter

Pulse Link is a Flutter mobile app for daily blood donation workflows and emergency SOS dispatch.

The current implementation is intentionally wired to mock data by default so the mobile team can work before the Laravel/Vue admin backend is finished.

## What Is Implemented

- Daily Mode
  - Hero Pass profile with blood type, hero level, donation count, total volume, and QR certificate.
  - Dynamic donation event list and map preview.
  - Booking/cancel appointment flow through a repository.
  - 84-day recovery tracker.
  - Donation history and manual log form.
- SOS Mode
  - Realtime alert entry point through `EmergencySignalService`.
  - Red alert visual mode.
  - Dispatch wave policy for 5 km, 30 km, and inter-province support.
  - Route plan display with animated priority path.
  - Hold-to-confirm button for 3 seconds.
  - Shared intensity value syncing ECG animation, route glow, and heartbeat audio service.
- Backend Integration Shape
  - Laravel REST repositories.
  - Firebase SOS listener.
  - Device GPS and audio service adapters.
  - API contract in `docs/backend_contract.md`.

## Run With Mock Data

```bash
flutter create .
flutter pub get
flutter run --dart-define=USE_MOCK_SERVICES=true
```

The debug SOS button on the home/profile screen emits a local mock alert.

Run `flutter create .` only if this repository still lacks Flutter platform folders such as `android/` and `ios/`.

## Run With Laravel + Firebase

```bash
flutter run \
  --dart-define=USE_MOCK_SERVICES=false \
  --dart-define=LARAVEL_API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=MOBILE_API_TOKEN=your-token
```

For Flutter web, pass Firebase web config explicitly when you want realtime SOS:

```bash
flutter run -d chrome \
  --dart-define=USE_MOCK_SERVICES=false \
  --dart-define=LARAVEL_API_BASE_URL=http://127.0.0.1:8000 \
  --dart-define=MOBILE_API_TOKEN=your-token \
  --dart-define=FIREBASE_WEB_API_KEY=your-api-key \
  --dart-define=FIREBASE_WEB_APP_ID=your-app-id \
  --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=your-sender-id \
  --dart-define=FIREBASE_WEB_PROJECT_ID=your-project-id \
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN=your-project.firebaseapp.com
```

If those Firebase web values are omitted, the app now still boots in real Laravel mode, but realtime SOS listening is disabled.

Before using real mode:

- Configure Firebase for Android/iOS with FlutterFire.
- Configure Firebase Web if you run with `-d chrome` and need realtime SOS listener.
- Add `assets/audio/heartbeat_loop.mp3` if you want real heartbeat audio.
- Implement the Laravel endpoints listed in `docs/backend_contract.md`.
- Keep Google Directions or map provider keys on Laravel; Flutter calls `/api/mobile/routes/plan`.

## Notes

Flutter and Dart SDKs were not available in this machine PATH during scaffolding, so `flutter analyze` and tests could not be executed here.
