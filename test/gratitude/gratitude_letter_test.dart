import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_link/features/daily/domain/blood_journey.dart';
import 'package:pulse_link/features/gratitude/domain/gratitude_letter.dart';
import 'package:pulse_link/features/notifications/domain/mobile_notification.dart';

void main() {
  test('thư kết thúc ca truyền máu luôn mang nguồn từ gia đình', () {
    final journey = BloodJourney(
      id: 'journey-patient',
      destinationType: 'patient',
      currentStep: 'transfused',
      finalMessage: 'Giọt máu đã đến với người bệnh.',
      completedAt: DateTime(2026, 7, 10),
      gratitudeCard: {
        'source': 'sos_pulselink',
        'messages': [
          {
            'sender': 'PulseLink',
            'title': 'Sai nguồn',
            'body': 'Không dùng lá thư cũ này.',
            'signature': 'PulseLink Team',
          },
        ],
      },
      steps: const [],
    );

    final letter = GratitudeLetter.fromBloodJourney(journey);

    expect(letter.source, GratitudeLetterSource.sosPatient);
    expect(letter.messages.single.sender, 'Người nhà bệnh nhân');
    expect(letter.messages.single.signature, 'Gia đình người nhận máu');
  });

  test('thư kết thúc hành trình dự trữ mang nguồn từ bệnh viện', () {
    final journey = BloodJourney(
      id: 'journey-reserve',
      destinationType: 'reserve',
      currentStep: 'stored',
      finalMessage: 'Đơn vị máu đã được lưu trữ an toàn.',
      completedAt: DateTime(2026, 7, 10),
      steps: const [],
    );

    final letter = GratitudeLetter.fromBloodJourney(journey);

    expect(letter.source, GratitudeLetterSource.sosReserve);
    expect(letter.messages.single.sender, 'Bệnh viện tiếp nhận');
    expect(letter.messages.single.signature, 'Đội ngũ y tế');
  });

  test('xác nhận hiến SOS mở thư cảm ơn ngay từ PulseLink', () {
    final letter = GratitudeLetter.maybeFromNotification(
      MobileNotification(
        id: 'donation-verified-1',
        type: 'donation_verified',
        title: 'Cảm ơn bạn đã hiến máu cứu người',
        body: 'Cảm ơn nghĩa cử cao đẹp của bạn!',
        createdAt: DateTime(2026, 7, 10),
        payload: const {
          'gratitude_card': {
            'id': 'sos-donation-journey-1',
            'source': 'sos_pulselink',
            'style': 'hero_night',
            'messages': [
              {
                'sender': 'PulseLink',
                'title': 'Một lá thư từ PulseLink',
                'body': 'Bạn vừa trao đi một cơ hội sống.',
                'signature': 'Đội ngũ PulseLink',
              },
            ],
          },
        },
      ),
    );

    expect(letter, isNotNull);
    expect(letter!.source, GratitudeLetterSource.sosPulseLink);
    expect(letter.messages.single.sender, 'PulseLink');
  });

  test('thư hành trình cũ bị cụt được thay bằng lời cảm ơn hoàn chỉnh', () {
    final letter = GratitudeLetter.maybeFromNotification(
      MobileNotification(
        id: 'journey-completed-truncated',
        type: 'blood_journey_completed',
        title: 'Thư cảm ơn từ hành trình giọt máu',
        body: 'Anh Trần Minh Quân ơi, cả nhà em',
        createdAt: DateTime(2026, 7, 11),
        payload: const {
          'destination_type': 'patient',
          'gratitude_card': {
            'id': 'journey-truncated',
            'source': 'sos_patient',
            'messages': [
              {
                'sender': 'Người nhà bệnh nhân',
                'title': 'Lời cảm ơn từ người nhà',
                'body': 'Anh Trần Minh Quân ơi, cả nhà em',
                'signature': 'Gia đình người nhận máu',
              },
            ],
          },
        },
      ),
    );

    expect(letter, isNotNull);
    expect(letter!.messages.single.body, isNot(contains('cả nhà em')));
    expect(letter.messages.single.body, endsWith('.'));
  });
}
