# Push Notification: APK va iOS

## Han vi thong bao

- SOS phu hop: gui ngay khi benh vien phat lenh, uu tien cao tren Android va Time Sensitive tren iOS. Khong dung Critical Alerts entitlement.
- Lich da dang ky: xac nhan ngay khi dat lich va nhac theo scheduler hien co.
- Sau hien: thu Pulse Link ngay khi benh vien xac nhan; tin cham soc sau hien duoc tao boi scheduler va nguoi dung co the tat rieng.
- Hanh trinh giot mau: chi gui cac moc nhan mau va hoan tat, khong spam tung buoc.
- Lich gan ban va cong dong mac dinh tat.
- Gio yen lang bo qua cac nhom thuong; SOS van duoc uu tien.

## Firebase Android

1. Tao Android app `asia.pulselink.app` trong Firebase va dat `google-services.json` vao `android/app/`.
2. Gradle tu ap dung Google Services plugin neu file ton tai. Khong commit file nay.
3. Build production voi `--dart-define=FIREBASE_PUSH_ENABLED=true`.

## Firebase iOS

1. Tao iOS app `asia.pulselink.app` trong Firebase, them `GoogleService-Info.plist` vao target Runner bang Xcode.
2. Bat Push Notifications va Background Modes / Remote notifications trong Signing & Capabilities.
3. Upload APNs authentication key vao Firebase. `Runner.entitlements` va `UIBackgroundModes` da duoc chuan bi trong repository.

## Backend

Khai bao mot trong hai bien sau tren Laravel production:

- `FIREBASE_SERVICE_ACCOUNT_PATH`: duong dan tuyet doi toi JSON service account ben ngoai repository.
- `FIREBASE_SERVICE_ACCOUNT_JSON`: JSON service account, chi dung trong secret manager.

Can co `FIREBASE_PROJECT_ID`. Dispatcher gui FCM qua HTTP v1, luu delivery theo tung thiet bi va vo hieu token FCM da bi huy. Khi Firebase chua duoc cau hinh, inbox va realtime van hoat dong; delivery duoc danh dau `skipped`.
