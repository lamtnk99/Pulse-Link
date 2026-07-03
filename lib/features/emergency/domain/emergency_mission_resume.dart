import 'emergency_alert.dart';
import 'emergency_commitment.dart';

class EmergencyMissionResume {
  const EmergencyMissionResume({
    required this.alert,
    required this.commitment,
  });

  factory EmergencyMissionResume.fromJson(Map<String, dynamic> json) {
    return EmergencyMissionResume(
      alert: EmergencyAlert.fromJson(
        json['alert'] as Map<String, dynamic>,
      ),
      commitment: EmergencyCommitment.fromJson(
        json['commitment'] as Map<String, dynamic>,
      ),
    );
  }

  final EmergencyAlert alert;
  final EmergencyCommitment commitment;
}
