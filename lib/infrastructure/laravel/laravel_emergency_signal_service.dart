import '../../features/emergency/domain/emergency_alert.dart';
import '../../features/profile/domain/donor_profile.dart';
import '../../services/emergency_signal_service.dart';
import '../firebase/firebase_emergency_signal_service.dart';
import 'laravel_api_client.dart';

class LaravelBackedEmergencySignalService implements EmergencySignalService {
  const LaravelBackedEmergencySignalService({
    FirebaseEmergencySignalService? firebaseSignalService,
    required LaravelApiClient apiClient,
  })  : _firebaseSignalService = firebaseSignalService,
        _apiClient = apiClient;

  final FirebaseEmergencySignalService? _firebaseSignalService;
  final LaravelApiClient _apiClient;

  @override
  Stream<EmergencyAlert> watchAlerts({
    required DonorProfile profile,
  }) {
    final firebaseSignalService = _firebaseSignalService;
    if (firebaseSignalService == null) {
      return const Stream<EmergencyAlert>.empty();
    }
    return firebaseSignalService.watchAlerts(profile: profile);
  }

  @override
  Future<void> confirmCommitment({
    required String alertId,
  }) async {
    await _apiClient.postJson(
      '/api/mobile/sos-alerts/$alertId/commit',
    );
    await _firebaseSignalService?.confirmCommitment(alertId: alertId);
  }

  @override
  Future<void> emitDebugAlert() {
    final firebaseSignalService = _firebaseSignalService;
    if (firebaseSignalService == null) {
      return Future<void>.value();
    }
    return firebaseSignalService.emitDebugAlert();
  }
}
