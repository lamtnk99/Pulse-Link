import 'dart:async';

import '../../features/emergency/domain/emergency_alert.dart';
import '../../features/emergency/domain/emergency_commitment.dart';
import '../../features/emergency/domain/emergency_mission_resume.dart';
import '../../features/notifications/domain/mobile_notification.dart';
import '../../features/profile/domain/donor_profile.dart';
import '../../core/location/geo_point.dart';
import '../../services/emergency_signal_service.dart';
import '../firebase/firebase_emergency_signal_service.dart';
import 'laravel_api_client.dart';
import 'reverb_realtime_client.dart';

class LaravelBackedEmergencySignalService implements EmergencySignalService {
  const LaravelBackedEmergencySignalService({
    FirebaseEmergencySignalService? firebaseSignalService,
    required LaravelApiClient apiClient,
    LaravelRealtimeConfig? fallbackRealtimeConfig,
    ReverbRealtimeClient reverbRealtimeClient = const ReverbRealtimeClient(),
  })  : _firebaseSignalService = firebaseSignalService,
        _apiClient = apiClient,
        _fallbackRealtimeConfig = fallbackRealtimeConfig,
        _reverbRealtimeClient = reverbRealtimeClient;

  final FirebaseEmergencySignalService? _firebaseSignalService;
  final LaravelApiClient _apiClient;
  final LaravelRealtimeConfig? _fallbackRealtimeConfig;
  final ReverbRealtimeClient _reverbRealtimeClient;

  @override
  Stream<EmergencyAlert> watchAlerts({
    required DonorProfile profile,
  }) {
    final streams = <Stream<EmergencyAlert>>[
      _watchReverbAlerts(profile: profile),
      _watchLaravelAlerts(profile: profile),
    ];
    final firebaseSignalService = _firebaseSignalService;
    if (firebaseSignalService != null) {
      streams.add(firebaseSignalService.watchAlerts(profile: profile));
    }
    return _mergeAlertStreams(streams);
  }

  @override
  Future<EmergencyMissionResume?> fetchActiveCommitment({
    required DonorProfile profile,
  }) async {
    final json = await _apiClient.getJson(
      '/api/mobile/me/sos-commitment?user_id=${Uri.encodeComponent(profile.id)}',
    );
    final data = json['data'];
    if (data == null) return null;
    if (data is! Map<String, dynamic>) return null;
    if (data['alert'] is! Map<String, dynamic> ||
        data['commitment'] is! Map<String, dynamic>) {
      return null;
    }

    return EmergencyMissionResume.fromJson(data);
  }

  @override
  Stream<MobileNotification> watchNotifications({
    required DonorProfile profile,
  }) async* {
    final config = await _fetchRealtimeConfig();
    if (config == null || !config.enabled) return;

    await for (final event in _reverbRealtimeClient.watch(
      config: config,
      channels: {config.donorChannelTemplate.replaceAll('{donor_id}', profile.id)},
    )) {
      if (event.name != config.notificationCreatedEvent) continue;
      final notification = event.data['notification'];
      if (notification is Map<String, dynamic>) {
        yield MobileNotification.fromJson(notification);
      }
    }
  }

  @override
  Stream<EmergencyCommitment> watchCommitments({
    required DonorProfile profile,
  }) async* {
    final config = await _fetchRealtimeConfig();
    if (config == null || !config.enabled) return;

    await for (final event in _reverbRealtimeClient.watch(
      config: config,
      channels: {config.donorChannelTemplate.replaceAll('{donor_id}', profile.id)},
    )) {
      if (event.name != 'emergency.commitment.updated') continue;
      final commitment = event.data['commitment'];
      if (commitment is Map<String, dynamic>) {
        yield EmergencyCommitment.fromJson(commitment);
      }
    }
  }

  @override
  Future<List<MobileNotification>> fetchNotifications({
    required DonorProfile profile,
  }) async {
    final notifications = await _apiClient.getList(
      '/api/mobile/me/notifications?user_id=${Uri.encodeComponent(profile.id)}',
    );
    return notifications
        .whereType<Map<String, dynamic>>()
        .map(MobileNotification.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> markNotificationRead({
    required DonorProfile profile,
    required String notificationId,
  }) async {
    await _apiClient.postJson(
      '/api/mobile/me/notifications/$notificationId/read?user_id=${Uri.encodeComponent(profile.id)}',
    );
  }

  @override
  Future<EmergencyCommitment> confirmCommitment({
    required String alertId,
    required String donorId,
    GeoPoint? location,
    int? etaMinutes,
  }) async {
    final json = await _apiClient.postJson(
      '/api/mobile/sos-alerts/$alertId/commit',
      body: {
        'donor_id': int.tryParse(donorId) ?? donorId,
        if (location != null) ...location.toJson(),
        if (etaMinutes != null) 'eta_minutes': etaMinutes,
      },
    );
    await _firebaseSignalService?.confirmCommitment(
      alertId: alertId,
      donorId: donorId,
      location: location,
      etaMinutes: etaMinutes,
    );

    final data = json['data'];
    return EmergencyCommitment.fromJson(
      data is Map<String, dynamic> ? data : json,
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
    await _apiClient.postJson(
      '/api/mobile/sos-alerts/$alertId/location',
      body: {
        'donor_id': int.tryParse(donorId) ?? donorId,
        ...location.toJson(),
        if (etaMinutes != null) 'eta_minutes': etaMinutes,
        'status': status.apiName,
      },
    );
  }

  @override
  Future<EmergencyCommitment> cancelCommitment({
    required String alertId,
    required String donorId,
    required String reason,
  }) async {
    final json = await _apiClient.postJson(
      '/api/mobile/sos-alerts/$alertId/cancel',
      body: {
        'donor_id': int.tryParse(donorId) ?? donorId,
        'cancel_reason': reason,
      },
    );
    final data = json['data'];
    return EmergencyCommitment.fromJson(
      data is Map<String, dynamic> ? data : json,
    );
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
        final alerts = await _fetchVisibleAlerts(profile: profile);
        for (final alert in _changedAlerts(alerts, seenSignatures)) {
          yield alert;
        }
      } on Object {
        // Polling is a fallback signal path; transient API failures should not
        // interrupt the app shell or the Firebase stream when it is configured.
      }

      await Future<void>.delayed(const Duration(seconds: 8));
    }
  }

  Stream<EmergencyAlert> _watchReverbAlerts({
    required DonorProfile profile,
  }) async* {
    final config = await _fetchRealtimeConfig();
    if (config == null || !config.enabled) return;

    final seenSignatures = <String, String>{};
    await for (final _ in _reverbRealtimeClient.watch(
      config: config,
      channels: config.channelsFor(profile.id),
    )) {
      try {
        final alerts = await _fetchVisibleAlerts(profile: profile);
        for (final alert in _changedAlerts(alerts, seenSignatures)) {
          yield alert;
        }
      } on Object {
        // The socket remains connected; the next realtime event or poll can
        // hydrate the visible alerts again.
      }
    }
  }

  Future<LaravelRealtimeConfig?> _fetchRealtimeConfig() async {
    try {
      final json = await _apiClient.getJson('/api/mobile/realtime-config');
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        final config = LaravelRealtimeConfig.fromJson(data);
        return config.enabled ? config : _fallbackRealtimeConfig;
      }
    } on Object {
      // Older API deployments may not expose realtime-config yet.
    }

    return _fallbackRealtimeConfig;
  }

  Future<List<EmergencyAlert>> _fetchVisibleAlerts({
    required DonorProfile profile,
  }) async {
    final alerts = await _apiClient.getList(
      '/api/mobile/sos-alerts?user_id=${Uri.encodeComponent(profile.id)}',
    );
    return alerts
        .whereType<Map<String, dynamic>>()
        .map(EmergencyAlert.fromJson)
        .toList(growable: false);
  }

  Iterable<EmergencyAlert> _changedAlerts(
    List<EmergencyAlert> alerts,
    Map<String, String> seenSignatures,
  ) sync* {
    for (final alert in alerts) {
      final signature = '${alert.active}:${alert.expiresAt.toIso8601String()}:'
          '${alert.currentCommitment?.id ?? ''}:'
          '${alert.currentCommitment?.status.apiName ?? ''}:'
          '${alert.currentCommitment?.lastLocationAt?.toIso8601String() ?? ''}:'
          '${alert.currentCommitment?.bloodJourney?.currentStep ?? ''}:'
          '${alert.currentCommitment?.bloodJourney?.completedAt?.toIso8601String() ?? ''}';
      if (seenSignatures[alert.id] == signature) continue;

      seenSignatures[alert.id] = signature;
      yield alert;
    }
  }

  Stream<EmergencyAlert> _mergeAlertStreams(
    List<Stream<EmergencyAlert>> streams,
  ) {
    final controller = StreamController<EmergencyAlert>();
    final subscriptions = <StreamSubscription<EmergencyAlert>>[];

    controller.onListen = () {
      for (final stream in streams) {
        subscriptions.add(stream.listen(
          controller.add,
          onError: controller.addError,
        ));
      }
    };
    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      subscriptions.clear();
    };

    return controller.stream;
  }
}
