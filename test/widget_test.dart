import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_link/app/pulse_link_app.dart';
import 'package:pulse_link/app/pulse_link_controller.dart';
import 'package:pulse_link/infrastructure/mock/mock_emergency_services.dart';
import 'package:pulse_link/infrastructure/mock/mock_repositories.dart';

void main() {
  testWidgets('Daily mode shows five Vietnamese navigation tabs', (
    WidgetTester tester,
  ) async {
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
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Sự kiện'), findsOneWidget);
    expect(find.text('Lịch đặt'), findsOneWidget);
    expect(find.text('Sổ hiến'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);

    await tester.tap(find.text('Lịch đặt'));
    await tester.pumpAndSettle();
    expect(find.text('Lịch đã đặt'), findsOneWidget);
  });
}
