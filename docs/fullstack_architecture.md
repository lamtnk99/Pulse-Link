# Pulse Link Full-stack Architecture

## Services

- `backend/`: Laravel 11 API, database, Reverb broadcasting, emergency dispatch orchestration, FCM HTTP v1 gateway.
- `admin/`: Vue 3 + Tailwind hospital dashboard with realtime map and SOS activation.
- root Flutter app: mobile donor experience.

## Backend Clean Architecture Layout

- `app/Domain`: pure domain policy such as blood compatibility, distance calculation, dispatch waves.
- `app/Repositories/Contracts`: repository interfaces.
- `app/Repositories/Eloquent`: database-backed implementations.
- `app/Services`: application orchestration and external gateways.
- `app/Http`: controllers, requests, resources.

## Local Run

Backend:

```bash
cd backend
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve
php artisan reverb:start
```

Admin:

```bash
cd admin
copy .env.example .env
npm install
npm run dev
```

## SOS Flow

1. Hospital opens Vue dashboard and triggers `POST /api/admin/emergency-alerts`.
2. `EmergencyDispatchService` creates alert, selects compatible donors using wave policy, persists recipients.
3. `FcmHttpV1PushNotificationGateway` sends push notification when Firebase credentials are configured.
4. `EmergencyAlertActivated` broadcasts through Laravel Reverb to hospital dashboard.
5. Flutter donor commits through `POST /api/mobile/sos-alerts/{publicId}/commit`.
6. `EmergencyCommitmentUpdated` updates map markers and stat counters over websockets.

## FCM Note

The PHP SDK was not installed because the local PHP CLI is missing `ext-sodium`. The project uses a clean `PushNotificationGateway` abstraction and an HTTP v1 gateway. For production, configure a real OAuth token provider or enable `ext-sodium` and swap in the Firebase SDK.
