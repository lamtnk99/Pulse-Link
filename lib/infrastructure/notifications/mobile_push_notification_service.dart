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
  Future<void>? _pendingTokenRegistration;
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

      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (_isAuthorized(settings.authorizationStatus)) {
        _scheduleTokenRegistration();
      }
    } catch (error) {
      debugPrint('PulseLink push: Firebase chưa sẵn sàng: $error');
    }
  }

  Future<bool> hasPermission() async {
    if (!isAvailable) return false;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return _isAuthorized(settings.authorizationStatus);
    } catch (error) {
      debugPrint('PulseLink push: chưa đọc được quyền thông báo: $error');
      return false;
    }
  }

  Future<PushPermissionStatus> requestPermission() async {
    if (!isAvailable) return PushPermissionStatus.unavailable;
    try {
      await _initializeLocalNotifications();
      final androidAllowed = await _requestAndroidNotificationPermission();
      if (androidAllowed == false) return PushPermissionStatus.denied;
      final settings = await _requestSystemPermission();
      if (!_isAuthorized(settings.authorizationStatus)) {
        return PushPermissionStatus.denied;
      }

      _scheduleTokenRegistration();
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

    final token = await _getFcmToken();
    if (token == null || token.isEmpty) {
      throw StateError(
        defaultTargetPlatform == TargetPlatform.iOS
            ? 'iPhone chưa nhận được APNs token. Hãy kiểm tra Push Notifications, '
                'APNs key trên Firebase và provisioning profile rồi mở lại ứng dụng.'
            : 'Thiết bị chưa lấy được FCM token.',
      );
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
      if (error is LaravelApiException) {
        final message = switch (error.statusCode) {
          429 =>
            'Bạn đang gửi thử quá nhanh. Vui lòng chờ một phút rồi thử lại.',
          404 => 'VPS chưa được cập nhật endpoint kiểm tra Firebase.',
          401 ||
          403 =>
            'Phiên đăng nhập không có quyền kiểm tra Firebase. Hãy đăng nhập lại.',
          _ => 'VPS không kiểm tra được Firebase (mã ${error.statusCode}).',
        };
        throw StateError(message);
      }
      throw StateError('Không kết nối được VPS để kiểm tra Firebase.');
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
      final token = await _getFcmToken(
        apnsTimeout: const Duration(seconds: 2),
      );
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

  void _scheduleTokenRegistration() {
    if (_pendingTokenRegistration != null) return;

    final registration = _registerCurrentToken();
    _pendingTokenRegistration = registration;
    unawaited(
      registration.whenComplete(() {
        if (identical(_pendingTokenRegistration, registration)) {
          _pendingTokenRegistration = null;
        }
      }),
    );
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await _getFcmToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token);
      } else {
        debugPrint(
          'PulseLink push: APNs/FCM token chưa sẵn sàng, sẽ đăng ký lại '
          'khi Firebase làm mới token.',
        );
      }
    } catch (error) {
      debugPrint('PulseLink push: chưa đăng ký được token thiết bị: $error');
    }
  }

  Future<String?> _getFcmToken({
    Duration apnsTimeout = const Duration(seconds: 15),
  }) async {
    final messaging = FirebaseMessaging.instance;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final deadline = DateTime.now().add(apnsTimeout);
      String? apnsToken;
      do {
        apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      } while (DateTime.now().isBefore(deadline));

      if (apnsToken == null || apnsToken.isEmpty) return null;
    }

    try {
      return await messaging.getToken();
    } on FirebaseException catch (error) {
      if (error.code == 'apns-token-not-set') return null;
      rethrow;
    }
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
