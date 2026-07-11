import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../../features/notifications/domain/notification_preferences.dart';
import '../../features/profile/domain/donor_profile.dart';
import '../laravel/laravel_api_client.dart';

@pragma('vm:entry-point')
Future<void> pulseLinkFirebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

enum PushPermissionStatus { unavailable, denied, granted }

class MobilePushNotificationService {
  MobilePushNotificationService({required LaravelApiClient apiClient})
      : _apiClient = apiClient;

  static const _firebaseEnabled = bool.fromEnvironment(
    'FIREBASE_PUSH_ENABLED',
    // Firebase is part of the mobile app runtime. Keeping this enabled by
    // default prevents release builds from silently skipping permission and
    // FCM token registration when a dart-define is omitted.
    defaultValue: true,
  );

  static const _sosChannel = AndroidNotificationChannel(
    'pulse_link_sos',
    'SOS khẩn cấp',
    description: 'Cảnh báo SOS phù hợp với hồ sơ người hiến của bạn.',
    importance: Importance.max,
  );

  static const _generalChannel = AndroidNotificationChannel(
    'pulse_link_general',
    'Pulse Link',
    description: 'Lịch hiến, chăm sóc sau hiến và cập nhật hành trình máu.',
    importance: Importance.defaultImportance,
  );

  final LaravelApiClient _apiClient;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  DonorProfile? _profile;
  ValueChanged<Map<String, dynamic>>? _onNotificationOpened;
  bool _initialized = false;

  bool get isAvailable => _firebaseEnabled && !kIsWeb;

  Future<void> start({
    required DonorProfile profile,
    required ValueChanged<Map<String, dynamic>> onNotificationOpened,
  }) async {
    _profile = profile;
    _onNotificationOpened = onNotificationOpened;
    if (!isAvailable) return;

    try {
      if (!_initialized) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await _initializeLocalNotifications();
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        FirebaseMessaging.onBackgroundMessage(
            pulseLinkFirebaseBackgroundHandler);
        _foregroundSubscription =
            FirebaseMessaging.onMessage.listen(_showForeground);
        _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
          _handleOpenedMessage,
        );
        _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
            .listen((token) => _registerToken(token));
        _initialized = true;
      }

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) _handleOpenedMessage(initialMessage);

      var settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        final androidAllowed = await _requestAndroidNotificationPermission();
        if (androidAllowed == false) return;
        settings = await _requestSystemPermission();
      }
      if (_isAuthorized(settings.authorizationStatus)) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) await _registerToken(token);
      }
    } catch (error) {
      debugPrint('PulseLink push: Firebase chưa sẵn sàng: $error');
    }
  }

  Future<PushPermissionStatus> requestPermission() async {
    if (!isAvailable) return PushPermissionStatus.unavailable;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _initializeLocalNotifications();
      final androidAllowed = await _requestAndroidNotificationPermission();
      if (androidAllowed == false) return PushPermissionStatus.denied;
      final settings = await _requestSystemPermission();
      if (!_isAuthorized(settings.authorizationStatus)) {
        return PushPermissionStatus.denied;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
      return PushPermissionStatus.granted;
    } catch (error) {
      debugPrint('PulseLink push: không xin được quyền: $error');
      return PushPermissionStatus.unavailable;
    }
  }

  Future<NotificationPreferences> fetchPreferences(DonorProfile profile) async {
    final json = await _apiClient.getJson(
      '/api/mobile/me/notification-preferences?user_id=${Uri.encodeComponent(profile.id)}',
    );
    final data = json['data'];
    return NotificationPreferences.fromJson(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  Future<String> sendTestNotification() async {
    final profile = _profile;
    if (profile == null) {
      throw StateError('Bạn cần đăng nhập trước khi kiểm tra thông báo.');
    }
    if (!isAvailable) {
      throw StateError('Firebase chưa được bật cho bản ứng dụng này.');
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _initializeLocalNotifications();
    } catch (error) {
      throw StateError('Firebase chưa khởi tạo được trên thiết bị: $error');
    }

    final androidAllowed = await _requestAndroidNotificationPermission();
    if (androidAllowed == false) {
      throw StateError('Quyền thông báo đang bị tắt trong cài đặt thiết bị.');
    }
    final settings = await _requestSystemPermission();
    if (!_isAuthorized(settings.authorizationStatus)) {
      throw StateError('Quyền thông báo đang bị tắt trong cài đặt thiết bị.');
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('Thiết bị chưa lấy được FCM token.');
    }
    try {
      await _registerToken(token);
    } catch (error) {
      throw StateError('Không đăng ký được FCM token với VPS: $error');
    }

    final Map<String, dynamic> response;
    try {
      response = await _apiClient.postJson(
        '/api/mobile/me/notifications/test?user_id=${Uri.encodeComponent(profile.id)}',
      );
    } catch (error) {
      throw StateError('VPS chưa chạy được kiểm tra Firebase: $error');
    }
    final data = response['data'];
    final result = data is Map<String, dynamic> ? data : response;
    final status = result['status']?.toString() ?? 'failed';
    final message = result['message']?.toString() ??
        'Không xác định được trạng thái gửi thông báo.';
    if (status != 'sent') throw StateError(message);

    return message;
  }

  Future<NotificationPreferences> savePreferences({
    required DonorProfile profile,
    required NotificationPreferences preferences,
  }) async {
    final json = await _apiClient.putJson(
      '/api/mobile/me/notification-preferences?user_id=${Uri.encodeComponent(profile.id)}',
      body: preferences.toJson(),
    );
    final data = json['data'];
    return NotificationPreferences.fromJson(
      data is Map<String, dynamic> ? data : preferences.toJson(),
    );
  }

  Future<void> unregister() async {
    final profile = _profile;
    if (!isAvailable || profile == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _apiClient.deleteJson(
          '/api/mobile/me/notification-devices?user_id=${Uri.encodeComponent(profile.id)}',
          body: {'token': token},
        );
      }
    } catch (error) {
      debugPrint('PulseLink push: chưa gỡ được thiết bị: $error');
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
  }

  Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        final data = jsonDecode(payload);
        if (data is Map<String, dynamic>) _onNotificationOpened?.call(data);
      },
    );
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_sosChannel);
    await androidPlugin?.createNotificationChannel(_generalChannel);
  }

  Future<NotificationSettings> _requestSystemPermission() {
    return FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<bool?> _requestAndroidNotificationPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final data = Map<String, dynamic>.from(message.data);
    final isSos = data['type'] == 'emergency_alert';
    final notification = message.notification;
    await _localNotifications.show(
      id: message.hashCode,
      title: notification?.title ?? 'Pulse Link',
      body: notification?.body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          isSos ? _sosChannel.id : _generalChannel.id,
          isSos ? _sosChannel.name : _generalChannel.name,
          channelDescription:
              isSos ? _sosChannel.description : _generalChannel.description,
          importance: isSos ? Importance.max : Importance.defaultImportance,
          priority: isSos ? Priority.max : Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    _onNotificationOpened?.call(Map<String, dynamic>.from(message.data));
  }

  Future<void> _registerToken(String token) async {
    final profile = _profile;
    if (profile == null) return;
    await _apiClient.postJson(
      '/api/mobile/me/notification-devices?user_id=${Uri.encodeComponent(profile.id)}',
      body: {
        'token': token,
        'platform':
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'app_version':
            const String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0'),
      },
    );
  }

  bool _isAuthorized(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }
}
