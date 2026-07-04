import 'package:shared_preferences/shared_preferences.dart';
import '../infrastructure/device/device_services.dart';
import '../infrastructure/laravel/laravel_api_client.dart';
import '../infrastructure/laravel/laravel_emergency_signal_service.dart';
import '../infrastructure/laravel/laravel_repositories.dart';
import '../infrastructure/laravel/reverb_realtime_client.dart';
import '../infrastructure/laravel/laravel_route_planner_service.dart';
import '../infrastructure/laravel/laravel_chat_service.dart';
import '../infrastructure/mock/mock_emergency_services.dart';
import '../infrastructure/mock/mock_repositories.dart';
import 'pulse_link_controller.dart';

class PulseLinkBootstrap {
  const PulseLinkBootstrap._();

  static const bool useMockServices = bool.fromEnvironment(
    'USE_MOCK_SERVICES',
    defaultValue: false,
  );

  static const String laravelBaseUrl = String.fromEnvironment(
    'LARAVEL_API_BASE_URL',
    defaultValue: 'https://api.pulselink.asia',
  );

  static const String mobileApiToken = String.fromEnvironment(
    'MOBILE_API_TOKEN',
    defaultValue: '',
  );

  static const String reverbAppKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'pulse-link-key',
  );

  static const String reverbHost = String.fromEnvironment(
    'REVERB_HOST',
    defaultValue: '',
  );

  static const int reverbPort = int.fromEnvironment(
    'REVERB_PORT',
    defaultValue: 443,
  );

  static const String reverbScheme = String.fromEnvironment(
    'REVERB_SCHEME',
    defaultValue: 'https',
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
        chatService: MockChatService(),
      );
    }

    final apiBaseUri = Uri.parse(laravelBaseUrl);
    final apiClient = LaravelApiClient(
      baseUrl: apiBaseUri,
      tokenProvider: () async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          return token;
        }
        return mobileApiToken.isEmpty ? null : mobileApiToken;
      },
    );
    final fallbackRealtimeConfig = reverbAppKey.isEmpty
        ? null
        : LaravelRealtimeConfig(
            enabled: true,
            key: reverbAppKey,
            host: reverbHost.isNotEmpty ? reverbHost : apiBaseUri.host,
            port: reverbPort,
            scheme: reverbScheme,
            globalChannel: 'mobile.emergency-alerts',
            donorChannelTemplate: 'mobile.donor.{donor_id}',
            alertActivatedEvent: 'emergency.alert.activated',
            commitmentUpdatedEvent: 'emergency.commitment.updated',
            notificationCreatedEvent: 'mobile.notification.created',
          );

    return PulseLinkController(
      donorRepository: LaravelDonorRepository(apiClient),
      eventRepository: LaravelDonationEventRepository(apiClient),
      historyRepository: LaravelDonationHistoryRepository(apiClient),
      communityPostRepository: LaravelCommunityPostRepository(apiClient),
      emergencySignalService: LaravelBackedEmergencySignalService(
        apiClient: apiClient,
        fallbackRealtimeConfig: fallbackRealtimeConfig,
      ),
      locationService: DeviceLocationService(),
      routePlannerService: LaravelRoutePlannerService(apiClient),
      audioService: JustAudioEmergencyAudioService(),
      chatService: LaravelChatService(apiClient),
    );
  }
}
