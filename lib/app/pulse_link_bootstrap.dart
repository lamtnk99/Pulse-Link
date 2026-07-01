import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../infrastructure/device/device_services.dart';
import '../infrastructure/firebase/firebase_emergency_signal_service.dart';
import '../infrastructure/laravel/laravel_api_client.dart';
import '../infrastructure/laravel/laravel_emergency_signal_service.dart';
import '../infrastructure/laravel/laravel_repositories.dart';
import '../infrastructure/laravel/laravel_route_planner_service.dart';
import '../infrastructure/mock/mock_emergency_services.dart';
import '../infrastructure/mock/mock_repositories.dart';
import 'pulse_link_controller.dart';

class PulseLinkBootstrap {
  const PulseLinkBootstrap._();

  static const bool useMockServices = bool.fromEnvironment(
    'USE_MOCK_SERVICES',
    defaultValue: true,
  );

  static const String laravelBaseUrl = String.fromEnvironment(
    'LARAVEL_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String mobileApiToken = String.fromEnvironment(
    'MOBILE_API_TOKEN',
    defaultValue: '',
  );

  static const String firebaseWebApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: '',
  );

  static const String firebaseWebAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '',
  );

  static const String firebaseWebMessagingSenderId = String.fromEnvironment(
    'FIREBASE_WEB_MESSAGING_SENDER_ID',
    defaultValue: '',
  );

  static const String firebaseWebProjectId = String.fromEnvironment(
    'FIREBASE_WEB_PROJECT_ID',
    defaultValue: '',
  );

  static const String firebaseWebAuthDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
    defaultValue: '',
  );

  static const String firebaseWebStorageBucket = String.fromEnvironment(
    'FIREBASE_WEB_STORAGE_BUCKET',
    defaultValue: '',
  );

  static const String firebaseWebMeasurementId = String.fromEnvironment(
    'FIREBASE_WEB_MEASUREMENT_ID',
    defaultValue: '',
  );

  static Future<PulseLinkController> createController() async {
    if (useMockServices) {
      final emergencySignalService = MockEmergencySignalService();
      return PulseLinkController(
        donorRepository: MockDonorRepository(),
        eventRepository: MockDonationEventRepository(),
        historyRepository: MockDonationHistoryRepository(),
        communityPostRepository: MockCommunityPostRepository(),
        emergencySignalService: emergencySignalService,
        locationService: MockLocationService(),
        routePlannerService: MockRoutePlannerService(),
        audioService: MockEmergencyAudioService(),
      );
    }

    final apiClient = LaravelApiClient(
      baseUrl: Uri.parse(laravelBaseUrl),
      tokenProvider: () async => mobileApiToken.isEmpty ? null : mobileApiToken,
    );
    final firebaseSignalService = await _initializeFirebaseSignalService();

    return PulseLinkController(
      donorRepository: LaravelDonorRepository(apiClient),
      eventRepository: LaravelDonationEventRepository(apiClient),
      historyRepository: LaravelDonationHistoryRepository(apiClient),
      communityPostRepository: LaravelCommunityPostRepository(apiClient),
      emergencySignalService: LaravelBackedEmergencySignalService(
        firebaseSignalService: firebaseSignalService,
        apiClient: apiClient,
      ),
      locationService: DeviceLocationService(),
      routePlannerService: LaravelRoutePlannerService(apiClient),
      audioService: JustAudioEmergencyAudioService(),
    );
  }

  static Future<FirebaseEmergencySignalService?>
      _initializeFirebaseSignalService() async {
    try {
      if (kIsWeb) {
        final options = _firebaseWebOptions;
        if (options == null) {
          return null;
        }
        await Firebase.initializeApp(options: options);
        return const FirebaseEmergencySignalService();
      }

      await Firebase.initializeApp();
      return const FirebaseEmergencySignalService();
    } on Object {
      return null;
    }
  }

  static FirebaseOptions? get _firebaseWebOptions {
    if (firebaseWebApiKey.isEmpty ||
        firebaseWebAppId.isEmpty ||
        firebaseWebMessagingSenderId.isEmpty ||
        firebaseWebProjectId.isEmpty) {
      return null;
    }

    return FirebaseOptions(
      apiKey: firebaseWebApiKey,
      appId: firebaseWebAppId,
      messagingSenderId: firebaseWebMessagingSenderId,
      projectId: firebaseWebProjectId,
      authDomain: firebaseWebAuthDomain.isEmpty ? null : firebaseWebAuthDomain,
      storageBucket: firebaseWebStorageBucket.isEmpty
          ? null
          : firebaseWebStorageBucket,
      measurementId: firebaseWebMeasurementId.isEmpty
          ? null
          : firebaseWebMeasurementId,
    );
  }
}
