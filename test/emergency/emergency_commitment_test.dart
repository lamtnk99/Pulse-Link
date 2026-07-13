import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_link/features/emergency/domain/emergency_commitment.dart';

void main() {
  test('journey progress realtime signal stays distinguishable from donation',
      () {
    final commitment = EmergencyCommitment.fromJson({
      'id': 12,
      'alert_id': 'alert-1',
      'update_type': 'journey_progress',
      'status': 'donated',
      'blood_journey': {
        'id': 'journey-1',
        'destination_type': 'patient',
        'current_step': 'emergency_transport',
        'published_at': '2026-07-13T10:00:00Z',
        'steps': [
          {
            'key': 'emergency_transport',
            'label': 'Đang vận chuyển cấp cứu',
            'completed': true,
          },
        ],
      },
    });

    expect(commitment.status, EmergencyCommitmentStatus.donated);
    expect(commitment.updateType, 'journey_progress');
    expect(commitment.bloodJourney?.currentStep, 'emergency_transport');
    expect(commitment.bloodJourney?.completedAt, isNull);

    final copied = commitment.copyWith();
    expect(copied.updateType, 'journey_progress');
  });
}
