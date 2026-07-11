import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_link/app/pulse_link_app.dart';
import 'package:pulse_link/app/pulse_link_controller.dart';
import 'package:pulse_link/infrastructure/mock/mock_emergency_services.dart';
import 'package:pulse_link/infrastructure/mock/mock_repositories.dart';
import 'package:pulse_link/infrastructure/laravel/laravel_api_client.dart';
import 'package:pulse_link/infrastructure/notifications/mobile_push_notification_service.dart';
import 'package:pulse_link/features/profile/domain/donor_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Daily mode shows five Vietnamese navigation tabs', (
    WidgetTester tester,
  ) async {
    // Cần token để qua cổng đăng nhập và vào thẳng Daily Mode (mock repo trả hồ sơ sẵn).
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
    final controller = PulseLinkController(
      donorRepository: MockDonorRepository(),
      eventRepository: MockDonationEventRepository(),
      historyRepository: MockDonationHistoryRepository(),
      communityPostRepository: MockCommunityPostRepository(),
      emergencySignalService: MockEmergencySignalService(),
      locationService: MockLocationService(),
      routePlannerService: MockRoutePlannerService(),
      audioService: MockEmergencyAudioService(),
      chatService: MockChatService(),
      donationFundService: MockDonationFundService(),
      communityImpactService: MockCommunityImpactService(),
    );

    await tester.pumpWidget(PulseLinkApp(controller: controller));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }

    for (final label in ['Trang chủ', 'Sự kiện', 'Lịch', 'Sổ hiến', 'Hồ sơ']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Lịch'));
    // Daily Mode có animation liên tục (nhịp đập, sóng) nên pumpAndSettle sẽ treo;
    // dùng pump có giới hạn để chờ tab chuyển.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      if (find.text('Lịch đã đặt').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text('Lịch đã đặt'), findsOneWidget);

    // Mở tab kích hoạt refreshDailyData() → mock service tạo các Future.delayed.
    // Drain hết để không còn timer treo khi test kết thúc.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('asks for notification permission once after login', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
    final pushService = _FakePushNotificationService();
    final controller = PulseLinkController(
      donorRepository: MockDonorRepository(),
      eventRepository: MockDonationEventRepository(),
      historyRepository: MockDonationHistoryRepository(),
      communityPostRepository: MockCommunityPostRepository(),
      emergencySignalService: MockEmergencySignalService(),
      locationService: MockLocationService(),
      routePlannerService: MockRoutePlannerService(),
      audioService: MockEmergencyAudioService(),
      chatService: MockChatService(),
      donationFundService: MockDonationFundService(),
      communityImpactService: MockCommunityImpactService(),
      pushNotificationService: pushService,
    );

    await tester.pumpWidget(PulseLinkApp(controller: controller));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.text('Không bỏ lỡ lời kêu gọi SOS').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('Không bỏ lỡ lời kêu gọi SOS'), findsOneWidget);
    await tester.tap(find.text('Bật thông báo'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(pushService.permissionRequested, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool('notification_permission_intro_seen_v1'),
      isTrue,
    );

    await tester.pump(const Duration(seconds: 1));
  });
}

class _FakePushNotificationService extends MobilePushNotificationService {
  _FakePushNotificationService()
      : super(
          apiClient: LaravelApiClient(
            baseUrl: Uri.parse('https://example.test'),
            tokenProvider: () async => 'test-token',
          ),
        );

  bool permissionRequested = false;

  @override
  bool get isAvailable => true;

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<PushPermissionStatus> requestPermission() async {
    permissionRequested = true;
    return PushPermissionStatus.granted;
  }

  @override
  Future<void> start({
    required DonorProfile profile,
    required ValueChanged<Map<String, dynamic>> onNotificationOpened,
  }) async {}
}
