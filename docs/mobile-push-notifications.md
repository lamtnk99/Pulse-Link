# Push Notification: APK và iOS

## Hành vi thông báo

- SOS phù hợp: gửi ngay khi bệnh viện phát lệnh, ưu tiên cao trên Android và Time Sensitive trên iOS. Không dùng quyền Critical Alerts.
- Lịch đã đăng ký: xác nhận ngay khi đặt lịch và nhắc theo scheduler hiện có.
- Sau hiến: thư Pulse Link được gửi ngay khi bệnh viện xác nhận; tin chăm sóc sau hiến do scheduler tạo và người dùng có thể tắt riêng.
- Hành trình giọt máu: chỉ gửi ở các mốc nhận máu và hoàn tất, không gửi dồn ở từng bước.
- Lịch gần bạn và thông báo cộng đồng mặc định tắt.
- Giờ yên lặng áp dụng với thông báo thông thường; SOS vẫn được ưu tiên.

## Firebase project

- Project name: `Pulse Link`.
- Project ID: `pulse-link-asia`.
- Android package và iOS bundle ID: `asia.pulselink.app`.
- `lib/firebase_options.dart` được sinh bằng FlutterFire CLI và được commit vì chỉ chứa cấu hình client công khai.
- `google-services.json`, `GoogleService-Info.plist` và service account JSON không được commit.

## Firebase Android

1. Đặt `google-services.json` vào `android/app/` trên máy build.
2. Gradle tự áp dụng Google Services plugin khi file tồn tại.
3. Build production với `--dart-define=FIREBASE_PUSH_ENABLED=true`.

## Firebase iOS

1. Đặt `GoogleService-Info.plist` vào `ios/Runner/` trên máy build hoặc dùng cấu hình trong `firebase_options.dart`.
2. Bật Push Notifications và Background Modes / Remote notifications trong Signing & Capabilities của Xcode.
3. Tải APNs Authentication Key (`.p8`) lên Firebase Cloud Messaging, kèm Key ID và Apple Team ID. `Runner.entitlements` và `UIBackgroundModes` đã được chuẩn bị trong repository.

## Backend Laravel

Khai báo trên production:

- `FIREBASE_PROJECT_ID=pulse-link-asia`.
- `FIREBASE_SERVICE_ACCOUNT_PATH`: đường dẫn tuyệt đối đến JSON service account nằm ngoài thư mục public và không thuộc Git.
- Hoặc `FIREBASE_SERVICE_ACCOUNT_JSON`: nội dung JSON lấy từ secret manager, không ghi trực tiếp vào repository.

Service account `pulse-link-fcm-sender@pulse-link-asia.iam.gserviceaccount.com` chỉ được gán custom role `pulseLinkFcmSender` với quyền `cloudmessaging.messages.create`. Dispatcher gửi FCM qua HTTP v1, lưu trạng thái delivery theo từng thiết bị và vô hiệu hóa token đã bị hủy. Khi Firebase chưa được cấu hình, inbox và realtime vẫn hoạt động; delivery được đánh dấu `skipped`.
