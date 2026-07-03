import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_link/core/location/geo_point.dart';
import 'package:pulse_link/features/emergency/domain/dispatch_wave.dart';
import 'package:pulse_link/features/emergency/domain/emergency_alert.dart';

void main() {
  group('DispatchWavePolicy', () {
    test('matches level 1 donors inside 15 km', () {
      final alert = _alert(EmergencyLevel.level1);
      final match = DispatchWavePolicy.evaluate(
        alert: alert,
        donorLocation: const GeoPoint(latitude: 10.8450, longitude: 106.6600),
        donorProvinceCode: 'HCM',
      );

      expect(match.isEligible, isTrue);
      expect(match.wave, DispatchWave.local5km);
    });

    test('keeps nearby donors in the first wave for expanded alerts', () {
      final alert = _alert(EmergencyLevel.level2);
      final match = DispatchWavePolicy.evaluate(
        alert: alert,
        donorLocation: const GeoPoint(latitude: 10.8450, longitude: 106.6600),
        donorProvinceCode: 'HCM',
      );

      expect(match.isEligible, isTrue);
      expect(match.wave, DispatchWave.local5km);
    });

    test('matches level 3 nearby inter-province donors', () {
      final alert = _alert(EmergencyLevel.level3);
      final match = DispatchWavePolicy.evaluate(
        alert: alert,
        donorLocation: const GeoPoint(latitude: 10.9700, longitude: 106.6500),
        donorProvinceCode: 'BD',
      );

      expect(match.isEligible, isTrue);
      expect(match.wave, DispatchWave.interProvince);
    });
  });
}

EmergencyAlert _alert(EmergencyLevel level) {
  final now = DateTime(2026, 7, 1, 13);
  return EmergencyAlert(
    id: 'sos-test',
    hospitalName: 'Benh vien Cho Ray',
    hospitalAddress: '201B Nguyen Chi Thanh, Quan 5, TP.HCM',
    hospitalProvinceCode: 'HCM',
    hospitalLocation: const GeoPoint(latitude: 10.7565, longitude: 106.6594),
    requiredBloodType: 'O+',
    level: level,
    unitsNeeded: 6,
    createdAt: now,
    expiresAt: now.add(const Duration(minutes: 30)),
    message: 'Test alert',
  );
}
