import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_link/features/daily/domain/blood_journey.dart';
import 'package:pulse_link/features/gratitude/domain/gratitude_letter.dart';

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
}
