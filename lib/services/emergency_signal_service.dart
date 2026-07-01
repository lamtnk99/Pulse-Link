import '../features/emergency/domain/emergency_alert.dart';
import '../features/profile/domain/donor_profile.dart';

abstract interface class EmergencySignalService {
  Stream<EmergencyAlert> watchAlerts({
    required DonorProfile profile,
  });

  Future<void> confirmCommitment({
    required String alertId,
  });

  Future<void> emitDebugAlert();
}
