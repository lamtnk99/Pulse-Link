import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/enums/app_mode.dart';
import '../core/enums/app_theme_preference.dart';
import '../core/location/geo_point.dart';
import '../core/utils/blood_compatibility.dart';
import '../features/community/domain/community_post.dart';
import '../features/daily/domain/donation_event.dart';
import '../features/daily/domain/past_donation.dart';
import '../features/emergency/domain/dispatch_wave.dart';
import '../features/emergency/domain/emergency_alert.dart';
import '../features/emergency/domain/emergency_commitment.dart';
import '../features/emergency/domain/emergency_mission_resume.dart';
import '../features/emergency/domain/route_plan.dart';
import '../features/notifications/domain/mobile_notification.dart';
import '../features/profile/domain/donor_profile.dart';
import '../infrastructure/laravel/laravel_api_client.dart';
import '../services/donation_event_repository.dart';
import '../services/donation_history_repository.dart';
import '../services/donor_repository.dart';
import '../services/community_post_repository.dart';
import '../services/emergency_audio_service.dart';
import '../services/emergency_signal_service.dart';
import '../services/location_service.dart';
import '../services/route_planner_service.dart';
import 'pulse_link_state.dart';

class PulseLinkController extends ChangeNotifier {
  PulseLinkController({
    required DonorRepository donorRepository,
    required DonationEventRepository eventRepository,
    required DonationHistoryRepository historyRepository,
    required CommunityPostRepository communityPostRepository,
    required EmergencySignalService emergencySignalService,
    required LocationService locationService,
    required RoutePlannerService routePlannerService,
    required EmergencyAudioService audioService,
  })  : _donorRepository = donorRepository,
        _eventRepository = eventRepository,
        _historyRepository = historyRepository,
        _communityPostRepository = communityPostRepository,
        _emergencySignalService = emergencySignalService,
        _locationService = locationService,
        _routePlannerService = routePlannerService,
        _audioService = audioService;

  final DonorRepository _donorRepository;
  final DonationEventRepository _eventRepository;
  final DonationHistoryRepository _historyRepository;
  final CommunityPostRepository _communityPostRepository;
  final EmergencySignalService _emergencySignalService;
  final LocationService _locationService;
  final RoutePlannerService _routePlannerService;
  final EmergencyAudioService _audioService;

  StreamSubscription<EmergencyAlert>? _alertSubscription;
  StreamSubscription<MobileNotification>? _notificationSubscription;
  Timer? _locationSyncTimer;
  bool _isSyncingEmergencyLocation = false;
  GeoPoint? _lastKnownLocation;
  PulseLinkState _state = PulseLinkState.initial();
  static const _themePreferenceKey = 'pulse_link_theme_preference';

  PulseLinkState get state => _state;

  Future<void> initialize() async {
    final themePreference = await _loadThemePreference();
    _state = _state.copyWith(
      isLoading: true,
      themePreference: themePreference,
      clearInitializationError: true,
    );
    notifyListeners();

    try {
      final profile = await _donorRepository.getCurrentProfile();
      final origin = await _resolveCurrentLocation();
      final events = await _eventRepository.getUpcomingEvents(origin: origin);
      final bookedAppointments = await _eventRepository.getBookedAppointments();
      final communityPosts = await _communityPostRepository.getPublishedPosts();
      final history = await _historyRepository.getDonationHistory();
      final notifications = await _emergencySignalService.fetchNotifications(
        profile: profile,
      );

      _state = _state.copyWith(
        isLoading: false,
        profile: profile,
        events: events,
        bookedAppointments: bookedAppointments,
        communityPosts: communityPosts,
        donationHistory: history,
        notifications: notifications,
        clearInitializationError: true,
      );
      notifyListeners();

      await _restoreActiveEmergencyMission(profile);

      await _alertSubscription?.cancel();
      _alertSubscription = _emergencySignalService
          .watchAlerts(profile: profile)
          .listen(_handleEmergencyAlert);
      await _notificationSubscription?.cancel();
      _notificationSubscription = _emergencySignalService
          .watchNotifications(profile: profile)
          .listen(_handleMobileNotification);
    } catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        initializationError: error.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> setThemePreference(AppThemePreference preference) async {
    _state = _state.copyWith(themePreference: preference);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, preference.name);
  }

  Future<void> refreshDailyData() async {
    final profile = await _donorRepository.getCurrentProfile();
    final origin = await _resolveCurrentLocation();
    final events = await _eventRepository.getUpcomingEvents(origin: origin);
    final bookedAppointments = await _eventRepository.getBookedAppointments();
    final communityPosts = await _communityPostRepository.getPublishedPosts();
    final history = await _historyRepository.getDonationHistory();
    final notifications = await _emergencySignalService.fetchNotifications(
      profile: profile,
    );

    _state = _state.copyWith(
      profile: profile,
      events: events,
      bookedAppointments: bookedAppointments,
      communityPosts: communityPosts,
      donationHistory: history,
      notifications: notifications,
    );
    notifyListeners();
  }

  Future<void> handleAppResumed() async {
    final profile = _state.profile;
    if (profile == null) return;

    try {
      final resume = await _emergencySignalService.fetchActiveCommitment(
        profile: profile,
      );
      if (resume == null) {
        final activeAlertId = _state.activeAlert?.id;
        if (activeAlertId != null &&
            _state.sosMissionPhase == SosMissionPhase.missionActive) {
          await _removeEmergencyAlert(activeAlertId);
        }
        return;
      }

      await _restoreActiveEmergencyMission(profile, resume: resume);
    } on Object {
      // Rehydration on resume is best-effort; the existing stream and polling
      // loop continue to reconcile SOS state.
    }
  }

  Future<void> toggleBooking(DonationEvent event) async {
    final origin = _lastKnownLocation;
    final updated = event.booked
        ? await _eventRepository.cancelAppointment(event.id, origin: origin)
        : await _eventRepository.bookAppointment(event.id, origin: origin);
    final bookedAppointments = await _eventRepository.getBookedAppointments();

    _state = _state.copyWith(
      events: _state.events
          .map((candidate) => candidate.id == updated.id ? updated : candidate)
          .toList(growable: false),
      bookedAppointments: bookedAppointments,
    );
    notifyListeners();
  }

  Future<DonationEvent> loadEventDetail(String eventId) {
    return _eventRepository.getEventDetail(
      eventId,
      origin: _lastKnownLocation,
    );
  }

  Future<GeoPoint?> _resolveCurrentLocation() async {
    try {
      _lastKnownLocation = await _locationService.getCurrentLocation();
    } on Object {
      // Location permission is optional for daily mode; backend can still fall
      // back to the demo user's saved location.
    }
    return _lastKnownLocation;
  }

  Future<CommunityPost> loadCommunityPost(String slug) {
    return _communityPostRepository.getPostDetail(slug);
  }

  Future<void> logDonation(PastDonationDraft draft) async {
    final profile = _state.profile;
    if (profile == null) return;

    final donation = await _historyRepository.addDonation(draft);
    final updatedProfile = profile.copyWith(
      totalDonations: profile.totalDonations + 1,
      points: profile.points + 250,
      lastDonationDate: donation.donatedAt,
    );
    await _donorRepository.saveProfile(updatedProfile);

    _state = _state.copyWith(
      profile: updatedProfile,
      donationHistory: [donation, ..._state.donationHistory],
    );
    notifyListeners();
  }

  Future<void> markNotificationRead(String notificationId) async {
    final profile = _state.profile;
    if (profile == null) return;

    await _emergencySignalService.markNotificationRead(
      profile: profile,
      notificationId: notificationId,
    );
    _state = _state.copyWith(
      notifications: _state.notifications
          .map(
            (notification) => notification.id == notificationId
                ? MobileNotification(
                    id: notification.id,
                    type: notification.type,
                    title: notification.title,
                    body: notification.body,
                    payload: notification.payload,
                    readAt: DateTime.now(),
                    createdAt: notification.createdAt,
                  )
                : notification,
          )
          .toList(growable: false),
    );
    notifyListeners();
  }

  void _handleMobileNotification(MobileNotification notification) {
    final notifications = [
      notification,
      ..._state.notifications.where((item) => item.id != notification.id),
    ];
    _state = _state.copyWith(notifications: notifications);
    notifyListeners();
  }

  Future<void> simulateSosAlert() async {
    await _emergencySignalService.emitDebugAlert();
  }

  Future<void> _handleEmergencyAlert(EmergencyAlert alert) async {
    if (!alert.active || alert.isExpired) {
      await _removeEmergencyAlert(alert.id);
      return;
    }

    final alertCommitment = _restorableAlertCommitment(alert);
    if (alert.currentCommitment != null && alertCommitment == null) {
      await _removeEmergencyAlert(alert.id);
      if (alert.currentCommitment?.status ==
          EmergencyCommitmentStatus.donated) {
        unawaited(refreshDailyData());
      }
      return;
    }
    final prepared = await _prepareEmergency(
      alert,
      requireEligibility: alertCommitment == null,
    );
    if (prepared == null) return;

    await _audioService.startHeartbeat(
      intensity: alertCommitment == null ? 0.35 : 1,
    );

    final nextAlerts = [
      alert,
      ..._state.activeAlerts.where((candidate) => candidate.id != alert.id),
    ];
    final currentFocusedCommitted = _state.activeAlert != null &&
        _state.committedAlertIds.contains(_state.activeAlert!.id);
    final shouldFocusAlert = _state.activeAlert == null ||
        (alertCommitment != null && !currentFocusedCommitted);
    final committedAlertIds = alertCommitment == null
        ? _state.committedAlertIds
        : {..._state.committedAlertIds, alert.id};
    final focusedAlertId = shouldFocusAlert ? alert.id : _state.activeAlert?.id;
    final focusedCommitted =
        focusedAlertId != null && committedAlertIds.contains(focusedAlertId);

    _state = _state.copyWith(
      activeMode: AppMode.sos,
      activeAlerts: nextAlerts,
      activeAlert: shouldFocusAlert ? alert : _state.activeAlert,
      committedAlertIds: committedAlertIds,
      activeEmergencyCommitment: shouldFocusAlert && alertCommitment != null
          ? alertCommitment
          : _state.activeEmergencyCommitment,
      sosMissionPhase: focusedCommitted
          ? SosMissionPhase.missionActive
          : SosMissionPhase.alertPreview,
      emergencyLocation:
          shouldFocusAlert ? prepared.donorLocation : _state.emergencyLocation,
      locationSyncError: shouldFocusAlert
          ? prepared.locationWarning
          : _state.locationSyncError,
      dispatchMatch:
          shouldFocusAlert ? prepared.dispatchMatch : _state.dispatchMatch,
      routePlan: shouldFocusAlert ? prepared.routePlan : _state.routePlan,
      sosIntensity: focusedCommitted ? 1 : 0.35,
      emergencyCommitted: focusedCommitted,
    );
    notifyListeners();
    if (focusedCommitted) _startEmergencyLocationSync();
  }

  Future<void> selectEmergencyAlert(String alertId) async {
    EmergencyAlert? alert;
    for (final candidate in _state.activeAlerts) {
      if (candidate.id == alertId) {
        alert = candidate;
        break;
      }
    }
    if (alert == null) return;

    final alertCommitment = _restorableAlertCommitment(alert);
    final prepared = await _prepareEmergency(
      alert,
      requireEligibility: alertCommitment == null,
    );
    if (prepared == null) return;
    final isCommitted =
        _state.committedAlertIds.contains(alert.id) || alertCommitment != null;
    final committedAlertIds = isCommitted
        ? {..._state.committedAlertIds, alert.id}
        : _state.committedAlertIds;

    _state = _state.copyWith(
      activeMode: AppMode.sos,
      activeAlert: alert,
      committedAlertIds: committedAlertIds,
      activeEmergencyCommitment:
          alertCommitment ?? _state.activeEmergencyCommitment,
      sosMissionPhase: isCommitted
          ? SosMissionPhase.missionActive
          : SosMissionPhase.alertPreview,
      emergencyLocation: prepared.donorLocation,
      locationSyncError: prepared.locationWarning,
      dispatchMatch: prepared.dispatchMatch,
      routePlan: prepared.routePlan,
      sosIntensity: isCommitted ? 1 : 0.35,
      emergencyCommitted: isCommitted,
    );
    notifyListeners();
    if (isCommitted) _startEmergencyLocationSync();
  }

  Future<void> commitToEmergency() async {
    final alert = _state.activeAlert;
    final profile = _state.profile;
    if (alert == null || profile == null) return;

    try {
      final location = await _tryCurrentLocation();
      final routePlan = _state.routePlan;
      final commitment = await _emergencySignalService.confirmCommitment(
        alertId: alert.id,
        donorId: profile.id,
        location: location,
        etaMinutes: routePlan?.estimatedMinutes,
      );
      await _audioService.confirmedPulse();

      final committedAlertIds = {..._state.committedAlertIds, alert.id};
      _state = _state.copyWith(
        committedAlertIds: committedAlertIds,
        emergencyCommitted: true,
        sosMissionPhase: SosMissionPhase.missionActive,
        activeEmergencyCommitment: commitment,
        emergencyLocation: location,
        locationSyncError: location == null
            ? 'Chưa lấy được vị trí hiện tại. Bạn vẫn có thể mở chỉ đường tới bệnh viện.'
            : null,
        clearLocationSyncError: location != null,
        sosIntensity: 1,
      );
      notifyListeners();
      _startEmergencyLocationSync();
    } on LaravelApiException catch (error) {
      final message = _laravelMessage(error) ??
          'Ca SOS này hiện không còn nhận thêm cam kết.';
      _state = _state.copyWith(
        sosIntensity: 0,
        locationSyncError: message,
      );
      notifyListeners();
      rethrow;
    } on Object {
      _state = _state.copyWith(
        sosIntensity: 0,
        locationSyncError:
            'Chưa xác nhận được cam kết SOS. Kiểm tra kết nối rồi giữ lại một lần nữa.',
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelEmergencyCommitment(String reason) async {
    final alert = _state.activeAlert;
    final profile = _state.profile;
    if (alert == null || profile == null) return;

    _stopEmergencyLocationSync();
    final commitment = await _emergencySignalService.cancelCommitment(
      alertId: alert.id,
      donorId: profile.id,
      reason: reason,
    );
    final committedAlertIds = {..._state.committedAlertIds}..remove(alert.id);
    _state = _state.copyWith(
      activeEmergencyCommitment: commitment,
      committedAlertIds: committedAlertIds,
      emergencyCommitted: false,
      sosMissionPhase: SosMissionPhase.alertPreview,
    );
    notifyListeners();

    await _removeEmergencyAlert(alert.id);
  }

  void updateSosIntensity(double value) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    _state = _state.copyWith(sosIntensity: clamped);
    _audioService.updateIntensity(clamped);
    notifyListeners();
  }

  Future<void> dismissEmergency() async {
    final dismissedAlertId = _state.activeAlert?.id;
    if (dismissedAlertId == null) return;
    await _removeEmergencyAlert(dismissedAlertId);
  }

  Future<void> _removeEmergencyAlert(String alertId) async {
    final wasFocusedAlert = _state.activeAlert?.id == alertId;
    if (wasFocusedAlert) {
      _stopEmergencyLocationSync();
    }
    final remainingAlerts = _state.activeAlerts
        .where((alert) => alert.id != alertId)
        .toList(growable: false);

    if (remainingAlerts.isNotEmpty && wasFocusedAlert) {
      final nextAlert = remainingAlerts.first;
      final isCommitted = _state.committedAlertIds.contains(nextAlert.id);
      final prepared = await _prepareEmergency(
        nextAlert,
        requireEligibility: !isCommitted,
      );
      if (prepared != null) {
        _state = _state.copyWith(
          activeAlerts: remainingAlerts,
          activeAlert: nextAlert,
          sosMissionPhase: isCommitted
              ? SosMissionPhase.missionActive
              : SosMissionPhase.alertPreview,
          clearActiveEmergencyCommitment: true,
          emergencyLocation: prepared.donorLocation,
          locationSyncError: prepared.locationWarning,
          dispatchMatch: prepared.dispatchMatch,
          routePlan: prepared.routePlan,
          sosIntensity: isCommitted ? 1 : 0.35,
          emergencyCommitted: isCommitted,
        );
        if (isCommitted) _startEmergencyLocationSync();
        notifyListeners();
        return;
      }
    }

    if (remainingAlerts.isNotEmpty) {
      _state = _state.copyWith(activeAlerts: remainingAlerts);
      notifyListeners();
      return;
    }

    await _audioService.stop();
    _state = _state.copyWith(
      activeMode: AppMode.daily,
      activeAlerts: const [],
      clearActiveAlert: true,
      sosMissionPhase: SosMissionPhase.alertPreview,
      clearActiveEmergencyCommitment: true,
      clearEmergencyLocation: true,
      clearLocationSyncError: true,
      clearDispatchMatch: true,
      clearRoutePlan: true,
      sosIntensity: 0,
      emergencyCommitted: false,
    );
    notifyListeners();
  }

  Future<void> _restoreActiveEmergencyMission(
    DonorProfile profile, {
    EmergencyMissionResume? resume,
  }) async {
    try {
      final missionResume = resume ??
          await _emergencySignalService.fetchActiveCommitment(
            profile: profile,
          );
      if (missionResume == null) return;
      if (!_isRestorableCommitment(missionResume.commitment)) return;
      if (!missionResume.alert.active || missionResume.alert.isExpired) return;

      final prepared = await _prepareEmergency(
        missionResume.alert,
        requireEligibility: false,
      );
      if (prepared == null) return;

      final restoredLocation =
          prepared.donorLocation ?? missionResume.commitment.location;
      final restoredRoutePlan = restoredLocation == null
          ? prepared.routePlan
          : await _planRouteSafely(
              origin: restoredLocation,
              destination: missionResume.alert.hospitalLocation,
              preferredDistanceKm: restoredLocation.distanceKmTo(
                missionResume.alert.hospitalLocation,
              ),
            );
      if (restoredLocation != null) {
        _lastKnownLocation = restoredLocation;
      }

      _state = _state.copyWith(
        activeMode: AppMode.sos,
        activeAlerts: [
          missionResume.alert,
          ..._state.activeAlerts.where(
            (alert) => alert.id != missionResume.alert.id,
          ),
        ],
        activeAlert: missionResume.alert,
        committedAlertIds: {
          ..._state.committedAlertIds,
          missionResume.alert.id,
        },
        activeEmergencyCommitment: missionResume.commitment,
        emergencyCommitted: true,
        sosMissionPhase: SosMissionPhase.missionActive,
        emergencyLocation: restoredLocation,
        locationSyncError: prepared.locationWarning,
        clearLocationSyncError: restoredLocation != null,
        dispatchMatch: prepared.dispatchMatch,
        routePlan: restoredRoutePlan,
        sosIntensity: 1,
      );
      notifyListeners();

      await _audioService.startHeartbeat(intensity: 1);
      _startEmergencyLocationSync();
    } on Object {
      // A resume check is best-effort; live SOS polling still runs afterwards.
    }
  }

  bool _isRestorableCommitment(EmergencyCommitment commitment) {
    return commitment.status == EmergencyCommitmentStatus.committed ||
        commitment.status == EmergencyCommitmentStatus.enRoute;
  }

  EmergencyCommitment? _restorableAlertCommitment(EmergencyAlert alert) {
    final commitment = alert.currentCommitment;
    if (commitment == null) return null;
    return _isRestorableCommitment(commitment) ? commitment : null;
  }

  Future<_PreparedEmergency?> _prepareEmergency(
    EmergencyAlert alert, {
    bool requireEligibility = true,
  }) async {
    final profile = _state.profile;
    if (profile == null) return null;

    final isCompatible = BloodCompatibility.canDonateTo(
      donorBloodType: profile.bloodType,
      recipientBloodType: alert.requiredBloodType,
    );
    if (!isCompatible) return null;

    final liveLocation = await _tryCurrentLocation();
    final locationWarning = liveLocation == null
        ? 'Chưa lấy được vị trí hiện tại. Bạn vẫn có thể mở chỉ đường tới bệnh viện.'
        : null;
    final currentLocation = liveLocation ?? alert.hospitalLocation;
    final distanceKm = currentLocation.distanceKmTo(alert.hospitalLocation);
    final dispatchMatch = liveLocation == null
        ? const DispatchMatch(
            wave: DispatchWave.local5km,
            distanceKm: 0,
            isEligible: true,
            reason:
                'Ứng dụng chưa xác định được vị trí hiện tại, hãy mở chỉ đường và bật GPS khi có thể.',
          )
        : DispatchWavePolicy.evaluate(
            alert: alert,
            donorLocation: currentLocation,
            donorProvinceCode: profile.provinceCode,
          );

    if (!dispatchMatch.isEligible && requireEligibility) return null;

    final routePlan = await _planRouteSafely(
      origin: currentLocation,
      destination: alert.hospitalLocation,
      preferredDistanceKm: distanceKm,
    );

    return _PreparedEmergency(
      dispatchMatch: dispatchMatch,
      routePlan: routePlan,
      donorLocation: liveLocation,
      locationWarning: locationWarning,
    );
  }

  Future<GeoPoint?> _tryCurrentLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      _lastKnownLocation = location;
      return location;
    } on Object {
      return _lastKnownLocation;
    }
  }

  Future<RoutePlan> _planRouteSafely({
    required GeoPoint origin,
    required GeoPoint destination,
    double? preferredDistanceKm,
  }) async {
    try {
      return await _routePlannerService.planRoute(
        origin: origin,
        destination: destination,
        preferredDistanceKm: preferredDistanceKm,
      );
    } on Object {
      final distanceKm =
          preferredDistanceKm ?? origin.distanceKmTo(destination);
      return RoutePlan(
        polyline: [origin, destination],
        distanceKm: distanceKm,
        estimatedMinutes: (distanceKm / 24 * 60).ceil().clamp(3, 240).toInt(),
        summary: 'Tuyến đường tới bệnh viện',
      );
    }
  }

  void _startEmergencyLocationSync() {
    _stopEmergencyLocationSync();
    unawaited(_syncEmergencyLocation());
    _locationSyncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_syncEmergencyLocation()),
    );
  }

  void _stopEmergencyLocationSync() {
    _locationSyncTimer?.cancel();
    _locationSyncTimer = null;
    _isSyncingEmergencyLocation = false;
  }

  Future<void> _syncEmergencyLocation() async {
    if (_isSyncingEmergencyLocation) return;
    final alert = _state.activeAlert;
    if (alert == null ||
        _state.sosMissionPhase != SosMissionPhase.missionActive) {
      return;
    }

    _isSyncingEmergencyLocation = true;
    try {
      final profile = _state.profile;
      if (profile == null) return;
      final location = await _locationService.getCurrentLocation();
      _lastKnownLocation = location;
      final distanceKm = location.distanceKmTo(alert.hospitalLocation);
      final routePlan = await _planRouteSafely(
        origin: location,
        destination: alert.hospitalLocation,
        preferredDistanceKm: distanceKm,
      );
      await _emergencySignalService.updateCommitmentLocation(
        alertId: alert.id,
        donorId: profile.id,
        location: location,
        etaMinutes: routePlan.estimatedMinutes,
      );

      _state = _state.copyWith(
        emergencyLocation: location,
        routePlan: routePlan,
        activeEmergencyCommitment: _state.activeEmergencyCommitment?.copyWith(
          status: EmergencyCommitmentStatus.enRoute,
          location: location,
          etaMinutes: routePlan.estimatedMinutes,
          lastLocationAt: DateTime.now(),
        ),
        clearLocationSyncError: true,
      );
      notifyListeners();
    } on Object {
      _state = _state.copyWith(
        locationSyncError:
            'Chưa gửi được vị trí mới. Bạn vẫn có thể đi theo chỉ đường.',
      );
      notifyListeners();
    } finally {
      _isSyncingEmergencyLocation = false;
    }
  }

  @override
  void dispose() {
    _stopEmergencyLocationSync();
    _alertSubscription?.cancel();
    _notificationSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  Future<AppThemePreference> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawValue = prefs.getString(_themePreferenceKey);
      return AppThemePreference.values.firstWhere(
        (preference) => preference.name == rawValue,
        orElse: () => AppThemePreference.light,
      );
    } on Object {
      return AppThemePreference.light;
    }
  }
}

String? _laravelMessage(LaravelApiException error) {
  try {
    final decoded = jsonDecode(error.body);
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      return message is String && message.isNotEmpty ? message : null;
    }
  } on Object {
    return null;
  }
  return null;
}

class _PreparedEmergency {
  const _PreparedEmergency({
    required this.dispatchMatch,
    required this.routePlan,
    required this.donorLocation,
    this.locationWarning,
  });

  final DispatchMatch dispatchMatch;
  final RoutePlan routePlan;
  final GeoPoint? donorLocation;
  final String? locationWarning;
}
