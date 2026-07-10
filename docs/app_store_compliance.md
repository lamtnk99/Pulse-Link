# App Store Compliance Checklist - Pulse Link

## Public URLs

- Privacy Policy: `https://api.pulselink.asia/legal/privacy`
- Terms of Use: `https://api.pulselink.asia/legal/terms`
- Account Deletion Guide: `https://api.pulselink.asia/legal/delete-account`
- Support: `https://api.pulselink.asia/support`

All URLs must be reachable without login before App Review.
The mobile app opens these public Laravel routes from `PUBLIC_WEB_BASE_URL`. On the current VPS deployment, this value is `https://api.pulselink.asia`.

## Account Deletion

- In-app path: `Ho so` -> `Tai khoan & quyen rieng tu` -> `Xoa tai khoan`.
- API: `DELETE /api/mobile/me/account`
- Confirmation phrase: `XÓA TÀI KHOẢN` as shown by the app UI.
- Deletion model:
  - Delete account, Sanctum tokens, FCM/device token, notifications, chat, location, identity/CCCD URLs and uploaded ID-card images.
  - Keep medical/reporting records only after anonymizing direct user references.
  - Store only minimal deletion audit data in `account_deletion_logs`.

## App Privacy Labels

Declare at least these categories in App Store Connect:

- Contact Info: name, email, phone, address.
- Health: blood type, donation history, health notes/checkup chat context.
- Sensitive Info: national ID/CCCD and ID-card images.
- Location: approximate/precise location for nearby events and SOS dispatch.
- User Content: chat messages, donation messages, community content if public.
- Identifiers: user ID, device/FCM token.
- Usage Data/Diagnostics: API activity and error logs if enabled in production.

## iOS Permissions

`ios/Runner/Info.plist` must include:

- `NSLocationWhenInUseUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

Location must remain optional. If permission is denied, users can still set province/ward/address manually in profile.

## Build Defines

- API base URL: `--dart-define=LARAVEL_API_BASE_URL=https://api.pulselink.asia`
- Public web/legal URL: `--dart-define=PUBLIC_WEB_BASE_URL=https://api.pulselink.asia`
- Khi chạy local, app tự mở trang pháp lý trên cùng host với `LARAVEL_API_BASE_URL` nếu host là `localhost`, `127.0.0.1`, `10.0.2.2` hoặc IP mạng LAN. Vì vậy không cần truyền thêm `PUBLIC_WEB_BASE_URL` cho các lệnh chạy local trong README.
- Có thể ép URL trang pháp lý bằng `--dart-define=PUBLIC_WEB_BASE_URL=http://127.0.0.1:8000` khi cần kiểm thử một host khác.

## Fundraising

Cash donation is disabled by default for App Store builds:

- Backend flag: `APP_STORE_CASH_DONATION_ENABLED=false`
- Flutter flag: omit `--dart-define=APP_STORE_CASH_DONATION_ENABLED=true`

Only enable cash donation after nonprofit/payment compliance is ready. Hero Points donation can remain enabled because it does not sell digital goods or process real money.

## Review Notes

Prepare for App Store Connect:

- Donor demo account.
- Admin demo account if admin flow is shown during review.
- Live backend base URL.
- Public legal URLs above.
- Short explanation of SOS: coordination support only; medical decisions remain with hospitals.
- Short explanation of account deletion and anonymized retained records.
