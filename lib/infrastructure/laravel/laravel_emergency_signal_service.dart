import 'dart:async';

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
      return _watchLaravelAlerts(profile: profile);
    }
    return _mergeAlertStreams(
      firebaseSignalService.watchAlerts(profile: profile),
      _watchLaravelAlerts(profile: profile),
    );
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

  Stream<EmergencyAlert> _watchLaravelAlerts({
    required DonorProfile profile,
  }) async* {
    final seenSignatures = <String, String>{};

    while (true) {
      try {
        final alerts = await _apiClient.getList(
          '/api/mobile/sos-alerts?user_id=${Uri.encodeComponent(profile.id)}',
        );

        for (final item in alerts.cast<Map<String, dynamic>>()) {
          final alert = EmergencyAlert.fromJson(item);
          final signature =
              '${alert.active}:${alert.expiresAt.toIso8601String()}';
          if (seenSignatures[alert.id] == signature) continue;

          seenSignatures[alert.id] = signature;
          yield alert;
        }
      } on Object {
        // Polling is a fallback signal path; transient API failures should not
        // interrupt the app shell or the Firebase stream when it is configured.
      }

      await Future<void>.delayed(const Duration(seconds: 8));
    }
  }

  Stream<EmergencyAlert> _mergeAlertStreams(
    Stream<EmergencyAlert> primary,
    Stream<EmergencyAlert> fallback,
  ) {
    final controller = StreamController<EmergencyAlert>();
    StreamSubscription<EmergencyAlert>? primarySubscription;
    StreamSubscription<EmergencyAlert>? fallbackSubscription;

    controller.onListen = () {
      primarySubscription = primary.listen(
        controller.add,
        onError: controller.addError,
      );
      fallbackSubscription = fallback.listen(
        controller.add,
        onError: controller.addError,
      );
    };
    controller.onCancel = () async {
      await primarySubscription?.cancel();
      await fallbackSubscription?.cancel();
    };

    return controller.stream;
  }
}
