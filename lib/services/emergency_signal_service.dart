import '../features/emergency/domain/emergency_alert.dart';
import '../features/emergency/domain/emergency_commitment.dart';
import '../features/emergency/domain/emergency_mission_resume.dart';
import '../features/notifications/domain/mobile_notification.dart';
import '../features/profile/domain/donor_profile.dart';
import '../core/location/geo_point.dart';

abstract interface class EmergencySignalService {
  Stream<EmergencyAlert> watchAlerts({
    required DonorProfile profile,
  });

  Future<EmergencyMissionResume?> fetchActiveCommitment({
    required DonorProfile profile,
  });

  Stream<MobileNotification> watchNotifications({
    required DonorProfile profile,
  });

  Future<List<MobileNotification>> fetchNotifications({
    required DonorProfile profile,
  });

  Future<void> markNotificationRead({
    required DonorProfile profile,
    required String notificationId,
  });

  Future<EmergencyCommitment> confirmCommitment({
    required String alertId,
    required String donorId,
    GeoPoint? location,
    int? etaMinutes,
  });

  Future<void> updateCommitmentLocation({
    required String alertId,
    required String donorId,
    required GeoPoint location,
    int? etaMinutes,
    EmergencyCommitmentStatus status = EmergencyCommitmentStatus.enRoute,
  });

  Future<EmergencyCommitment> cancelCommitment({
    required String alertId,
    required String donorId,
    required String reason,
  });

  Future<void> emitDebugAlert();
}
