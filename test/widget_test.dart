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
    SharedPreferences.setMockInitialValues({});
    final controller = PulseLinkController(
      donorRepository: MockDonorRepository(),
      eventRepository: MockDonationEventRepository(),
      historyRepository: MockDonationHistoryRepository(),
      communityPostRepository: MockCommunityPostRepository(),
      emergencySignalService: MockEmergencySignalService(),
      locationService: MockLocationService(),
      routePlannerService: MockRoutePlannerService(),
      audioService: MockEmergencyAudioService(),
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
    await tester.pumpAndSettle();
    expect(find.text('Lịch đã đặt'), findsOneWidget);
  });
}
