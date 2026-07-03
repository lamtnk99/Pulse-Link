import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/emergency/domain/emergency_alert.dart';
import '../../features/profile/domain/donor_profile.dart';
import '../../services/emergency_signal_service.dart';
import '../mock/mock_data.dart';

class FirebaseEmergencySignalService implements EmergencySignalService {
  const FirebaseEmergencySignalService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  @override
  Stream<EmergencyAlert> watchAlerts({
    required DonorProfile profile,
  }) {
    return firestore
        .collection('sos_alerts')
        .where('blood_types', arrayContains: profile.bloodType)
        .snapshots()
        .expand((snapshot) => snapshot.docChanges)
        .map((change) => EmergencyAlert.fromJson(change.doc.data()!));
  }

  @override
  Future<void> confirmCommitment({
    required String alertId,
  }) async {
    await firestore.collection('sos_alerts').doc(alertId).collection('commits').add({
      'committed_at': FieldValue.serverTimestamp(),
      'source': 'flutter',
    });
  }

  @override
  Future<void> emitDebugAlert() async {
    final alert = MockData.emergencyAlert();
    await firestore
        .collection('sos_alerts')
        .doc(alert.id)
        .set({
      ..._debugAlertJson(alert),
      'active': true,
      'blood_types': ['O+', 'O-'],
    });
  }

  Map<String, dynamic> _debugAlertJson(EmergencyAlert alert) {
    return {
      'id': alert.id,
      'hospital_name': alert.hospitalName,
      'hospital_address': alert.hospitalAddress,
      'hospital_province_code': alert.hospitalProvinceCode,
      'hospital_location': alert.hospitalLocation.toJson(),
      'required_blood_type': alert.requiredBloodType,
      'level': alert.level.name,
      'units_needed': alert.unitsNeeded,
      'created_at': alert.createdAt.toIso8601String(),
      'expires_at': alert.expiresAt.toIso8601String(),
      'message': alert.message,
      'active': alert.active,
    };
  }
}
