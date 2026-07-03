import 'dart:async';

import '../../core/location/geo_point.dart';
import '../../features/emergency/domain/emergency_alert.dart';
import '../../features/emergency/domain/emergency_commitment.dart';
import '../../features/emergency/domain/emergency_mission_resume.dart';
import '../../features/emergency/domain/route_plan.dart';
import '../../features/profile/domain/donor_profile.dart';
import '../../services/emergency_audio_service.dart';
import '../../services/emergency_signal_service.dart';
import '../../services/location_service.dart';
import '../../services/route_planner_service.dart';
import 'mock_data.dart';

class MockEmergencySignalService implements EmergencySignalService {
  final StreamController<EmergencyAlert> _controller =
      StreamController<EmergencyAlert>.broadcast();

  @override
  Stream<EmergencyAlert> watchAlerts({
    required DonorProfile profile,
  }) {
    return _controller.stream.where((alert) => !alert.isExpired);
  }

  @override
  Future<EmergencyMissionResume?> fetchActiveCommitment({
    required DonorProfile profile,
  }) async {
    return null;
  }

  @override
  Future<EmergencyCommitment> confirmCommitment({
    required String alertId,
    GeoPoint? location,
    int? etaMinutes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return EmergencyCommitment(
      id: 'mock-$alertId',
      alertId: alertId,
      status: EmergencyCommitmentStatus.committed,
      location: location,
      etaMinutes: etaMinutes,
      committedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateCommitmentLocation({
    required String alertId,
    required GeoPoint location,
    int? etaMinutes,
    EmergencyCommitmentStatus status = EmergencyCommitmentStatus.enRoute,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  @override
  Future<EmergencyCommitment> cancelCommitment({
    required String alertId,
    required String reason,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return EmergencyCommitment(
      id: 'mock-$alertId',
      alertId: alertId,
      status: EmergencyCommitmentStatus.cancelled,
      cancelReason: reason,
      committedAt: DateTime.now(),
    );
  }

  @override
  Future<void> emitDebugAlert() async {
    _controller.add(MockData.emergencyAlert());
  }
}

class MockLocationService implements LocationService {
  @override
  Future<GeoPoint> getCurrentLocation() async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return const GeoPoint(latitude: 10.7727, longitude: 106.6663);
  }
}

class MockRoutePlannerService implements RoutePlannerService {
  @override
  Future<RoutePlan> planRoute({
    required GeoPoint origin,
    required GeoPoint destination,
    double? preferredDistanceKm,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final distanceKm = preferredDistanceKm ?? origin.distanceKmTo(destination);
    final estimatedMinutes =
        (distanceKm / 28 * 60).ceil().clamp(5, 180).toInt();

    return RoutePlan(
      polyline: [
        origin,
        GeoPoint(
          latitude: (origin.latitude + destination.latitude) / 2 + 0.006,
          longitude: (origin.longitude + destination.longitude) / 2 - 0.004,
        ),
        destination,
      ],
      distanceKm: distanceKm,
      estimatedMinutes: estimatedMinutes,
      summary: 'Tuyến ưu tiên qua Nguyễn Tri Phương',
    );
  }
}

class MockEmergencyAudioService implements EmergencyAudioService {
  double _intensity = 0;

  @override
  Future<void> startHeartbeat({
    required double intensity,
  }) async {
    _intensity = intensity;
  }

  @override
  Future<void> updateIntensity(double intensity) async {
    _intensity = intensity;
  }

  @override
  Future<void> confirmedPulse() async {
    _intensity = 1;
  }

  @override
  Future<void> stop() async {
    _intensity = 0;
  }

  @override
  Future<void> dispose() async {
    _intensity = 0;
  }
}
