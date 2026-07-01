import '../../../core/location/geo_point.dart';
import 'emergency_alert.dart';

class DispatchMatch {
  const DispatchMatch({
    required this.wave,
    required this.distanceKm,
    required this.isEligible,
    required this.reason,
  });

  final DispatchWave wave;
  final double distanceKm;
  final bool isEligible;
  final String reason;
}

enum DispatchWave {
  local5km,
  province30km,
  interProvince,
  outOfRange,
}

extension DispatchWaveDisplay on DispatchWave {
  String get label {
    return switch (this) {
      DispatchWave.local5km => 'Gợn sóng 1',
      DispatchWave.province30km => 'Gợn sóng 2',
      DispatchWave.interProvince => 'Chi viện liên tỉnh',
      DispatchWave.outOfRange => 'Ngoài phạm vi',
    };
  }
}

class DispatchWavePolicy {
  const DispatchWavePolicy._();

  static DispatchMatch evaluate({
    required EmergencyAlert alert,
    required GeoPoint donorLocation,
    required String donorProvinceCode,
  }) {
    final distanceKm = donorLocation.distanceKmTo(alert.hospitalLocation);
    final sameProvince = donorProvinceCode == alert.hospitalProvinceCode;

    if (alert.level == EmergencyLevel.level1 && distanceKm <= 5) {
      return DispatchMatch(
        wave: DispatchWave.local5km,
        distanceKm: distanceKm,
        isEligible: true,
        reason: 'Bạn nằm trong bán kính phản ứng nhanh 5 km.',
      );
    }

    if (alert.level == EmergencyLevel.level2 &&
        sameProvince &&
        distanceKm <= 30) {
      return DispatchMatch(
        wave: DispatchWave.province30km,
        distanceKm: distanceKm,
        isEligible: true,
        reason: 'Bạn nằm trong vùng điều phối nội tỉnh 30 km.',
      );
    }

    if (alert.level == EmergencyLevel.level3 && distanceKm <= 100) {
      return DispatchMatch(
        wave: DispatchWave.interProvince,
        distanceKm: distanceKm,
        isEligible: true,
        reason: 'Bạn thuộc nhóm chi viện khẩn cấp cho tỉnh lân cận.',
      );
    }

    return DispatchMatch(
      wave: DispatchWave.outOfRange,
      distanceKm: distanceKm,
      isEligible: false,
      reason: 'Tình nguyện viên chưa nằm trong vùng điều phối hiện tại.',
    );
  }
}
