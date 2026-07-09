# App Store Compliance Checklist - Pulse Link

## Public URLs

- Privacy Policy: `/legal/privacy`
- Terms of Use: `/legal/terms`
- Account Deletion Guide: `/legal/delete-account`
- Support: `/support`

All URLs must be reachable without login before App Review.

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
