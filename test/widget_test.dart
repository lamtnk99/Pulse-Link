import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_link/app/pulse_link_app.dart';
import 'package:pulse_link/app/pulse_link_controller.dart';
import 'package:pulse_link/infrastructure/mock/mock_emergency_services.dart';
import 'package:pulse_link/infrastructure/mock/mock_repositories.dart';
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
}
