import '../../core/location/geo_point.dart';
import '../../features/emergency/domain/emergency_alert.dart';
import '../../features/emergency/domain/emergency_commitment.dart';
import '../../features/emergency/domain/emergency_mission_resume.dart';
import '../../features/profile/domain/donor_profile.dart';
import '../../services/emergency_signal_service.dart';

class FirebaseEmergencySignalService implements EmergencySignalService {
  const FirebaseEmergencySignalService();

  @override
  Stream<EmergencyAlert> watchAlerts({
    required DonorProfile profile,
  }) {
    return const Stream<EmergencyAlert>.empty();
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
    required String donorId,
    GeoPoint? location,
    int? etaMinutes,
  }) async {
    return EmergencyCommitment(
      id: 'firebase-disabled-$alertId',
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
    required String donorId,
    required GeoPoint location,
    int? etaMinutes,
    EmergencyCommitmentStatus status = EmergencyCommitmentStatus.enRoute,
  }) async {
    return;
  }

  @override
  Future<EmergencyCommitment> cancelCommitment({
    required String alertId,
    required String donorId,
    required String reason,
  }) async {
    return EmergencyCommitment(
      id: 'firebase-disabled-$alertId',
      alertId: alertId,
      status: EmergencyCommitmentStatus.cancelled,
      cancelReason: reason,
      committedAt: DateTime.now(),
    );
  }

  @override
  Future<void> emitDebugAlert() async {
    return;
  }
}
