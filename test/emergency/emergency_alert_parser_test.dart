import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_link/features/emergency/domain/emergency_alert.dart';
import 'package:pulse_link/features/emergency/domain/emergency_commitment.dart';

void main() {
  test('EmergencyAlert parses current donor commitment', () {
    final alert = EmergencyAlert.fromJson({
      'id': 'sos-001',
      'hospital_name': 'Bệnh viện Hữu nghị Việt Tiệp',
      'hospital_address': 'Hải Phòng',
      'hospital_province_code': '31',
      'hospital_location': {
        'latitude': 20.8449,
        'longitude': 106.6881,
      },
      'required_blood_type': 'O+',
      'level': 'level1',
      'units_needed': 4,
      'created_at': '2026-07-04T08:00:00+07:00',
      'expires_at': '2026-07-04T09:00:00+07:00',
      'message': 'Cần hỗ trợ máu O+.',
      'active': true,
      'current_commitment': {
        'id': 12,
        'alert_id': 'sos-001',
        'status': 'en_route',
        'latitude': 20.86,
        'longitude': 106.68,
        'eta_minutes': 9,
      },
    });

    expect(alert.currentCommitment, isNotNull);
    expect(alert.currentCommitment!.alertId, 'sos-001');
    expect(alert.currentCommitment!.status, EmergencyCommitmentStatus.enRoute);
    expect(alert.currentCommitment!.etaMinutes, 9);
  });
}
