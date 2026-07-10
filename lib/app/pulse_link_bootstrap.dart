import 'package:shared_preferences/shared_preferences.dart';
import '../infrastructure/device/device_services.dart';
import '../infrastructure/laravel/laravel_api_client.dart';
import '../infrastructure/laravel/laravel_emergency_signal_service.dart';
import '../infrastructure/laravel/laravel_repositories.dart';
import '../infrastructure/laravel/reverb_realtime_client.dart';
import '../infrastructure/laravel/laravel_route_planner_service.dart';
import '../infrastructure/laravel/laravel_chat_service.dart';
import '../infrastructure/laravel/laravel_donation_fund_service.dart';
import '../infrastructure/laravel/laravel_community_impact_service.dart';
import '../infrastructure/notifications/mobile_push_notification_service.dart';
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

  static const String _configuredPublicWebBaseUrl = String.fromEnvironment(
    'PUBLIC_WEB_BASE_URL',
    defaultValue: '',
  );

  /// Legal pages use the local Laravel host while developing, unless an
  /// explicit public web host is supplied. Production uses the Laravel API
  /// host because it serves the public legal routes.
  static String get publicWebBaseUrl {
    if (_configuredPublicWebBaseUrl.isNotEmpty) {
      return _configuredPublicWebBaseUrl;
    }

    final apiBase = Uri.tryParse(laravelBaseUrl);
    if (apiBase != null && _isLocalDevelopmentHost(apiBase)) {
      return apiBase.origin;
    }

    return 'https://api.pulselink.asia';
  }

  static bool _isLocalDevelopmentHost(Uri uri) {
    final host = uri.host.toLowerCase();
    if (uri.scheme.isEmpty || host.isEmpty) return false;

    return host == 'localhost' ||
        host == '::1' ||
        host == '127.0.0.1' ||
        _isPrivateIpv4(host);
  }

  static bool _isPrivateIpv4(String host) {
    final segments = host.split('.');
    if (segments.length != 4) return false;

    final octets = segments.map(int.tryParse).toList();
    if (octets.any((octet) => octet == null || octet < 0 || octet > 255)) {
      return false;
    }

    final first = octets[0]!;
    final second = octets[1]!;
    return first == 10 ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168);
  }

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
        donationFundService: MockDonationFundService(),
        communityImpactService: MockCommunityImpactService(),
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
      donationFundService: LaravelDonationFundService(apiClient),
      communityImpactService: LaravelCommunityImpactService(apiClient),
      pushNotificationService:
          MobilePushNotificationService(apiClient: apiClient),
    );
  }
}
