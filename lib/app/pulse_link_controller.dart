import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/enums/app_mode.dart';
import '../core/location/geo_point.dart';
import '../core/utils/blood_compatibility.dart';
import '../features/community/domain/community_post.dart';
import '../features/daily/domain/donation_event.dart';
import '../features/daily/domain/past_donation.dart';
import '../features/emergency/domain/dispatch_wave.dart';
import '../features/emergency/domain/emergency_alert.dart';
import '../features/emergency/domain/route_plan.dart';
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
  GeoPoint? _lastKnownLocation;
  PulseLinkState _state = PulseLinkState.initial();

  PulseLinkState get state => _state;

  Future<void> initialize() async {
    _state = _state.copyWith(isLoading: true, clearInitializationError: true);
    notifyListeners();

    try {
      final profile = await _donorRepository.getCurrentProfile();
      final origin = await _resolveCurrentLocation();
      final events = await _eventRepository.getUpcomingEvents(origin: origin);
      final bookedAppointments = await _eventRepository.getBookedAppointments();
      final communityPosts = await _communityPostRepository.getPublishedPosts();
      final history = await _historyRepository.getDonationHistory();

      _state = _state.copyWith(
        isLoading: false,
        profile: profile,
        events: events,
        bookedAppointments: bookedAppointments,
        communityPosts: communityPosts,
        donationHistory: history,
        clearInitializationError: true,
      );
      notifyListeners();

      await _alertSubscription?.cancel();
      _alertSubscription = _emergencySignalService
          .watchAlerts(profile: profile)
          .listen(_handleEmergencyAlert);
    } catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        initializationError: error.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> refreshDailyData() async {
    final profile = await _donorRepository.getCurrentProfile();
    final origin = await _resolveCurrentLocation();
    final events = await _eventRepository.getUpcomingEvents(origin: origin);
    final bookedAppointments = await _eventRepository.getBookedAppointments();
    final communityPosts = await _communityPostRepository.getPublishedPosts();
    final history = await _historyRepository.getDonationHistory();

    _state = _state.copyWith(
      profile: profile,
      events: events,
      bookedAppointments: bookedAppointments,
      communityPosts: communityPosts,
      donationHistory: history,
    );
    notifyListeners();
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

  Future<void> simulateSosAlert() async {
    await _emergencySignalService.emitDebugAlert();
  }

  Future<void> _handleEmergencyAlert(EmergencyAlert alert) async {
    if (!alert.active || alert.isExpired) {
      await _removeEmergencyAlert(alert.id);
      return;
    }

    final prepared = await _prepareEmergency(alert);
    if (prepared == null) return;

    await _audioService.startHeartbeat(intensity: 0.35);

    final nextAlerts = [
      alert,
      ..._state.activeAlerts.where((candidate) => candidate.id != alert.id),
    ];
    final shouldFocusAlert = _state.activeAlert == null;

    _state = _state.copyWith(
      activeMode: AppMode.sos,
      activeAlerts: nextAlerts,
      activeAlert: shouldFocusAlert ? alert : _state.activeAlert,
      dispatchMatch:
          shouldFocusAlert ? prepared.dispatchMatch : _state.dispatchMatch,
      routePlan: shouldFocusAlert ? prepared.routePlan : _state.routePlan,
      sosIntensity: 0.35,
      emergencyCommitted: shouldFocusAlert
          ? _state.committedAlertIds.contains(alert.id)
          : _state.emergencyCommitted,
    );
    notifyListeners();
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

    final prepared = await _prepareEmergency(alert);
    if (prepared == null) return;

    _state = _state.copyWith(
      activeMode: AppMode.sos,
      activeAlert: alert,
      dispatchMatch: prepared.dispatchMatch,
      routePlan: prepared.routePlan,
      sosIntensity: _state.committedAlertIds.contains(alert.id) ? 1 : 0.35,
      emergencyCommitted: _state.committedAlertIds.contains(alert.id),
    );
    notifyListeners();
  }

  Future<void> commitToEmergency() async {
    final alert = _state.activeAlert;
    if (alert == null) return;

    await _emergencySignalService.confirmCommitment(alertId: alert.id);
    await _audioService.confirmedPulse();

    final committedAlertIds = {..._state.committedAlertIds, alert.id};
    _state = _state.copyWith(
      committedAlertIds: committedAlertIds,
      emergencyCommitted: true,
      sosIntensity: 1,
    );
    notifyListeners();
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
    final remainingAlerts = _state.activeAlerts
        .where((alert) => alert.id != alertId)
        .toList(growable: false);

    if (remainingAlerts.isNotEmpty && wasFocusedAlert) {
      final nextAlert = remainingAlerts.first;
      final prepared = await _prepareEmergency(nextAlert);
      if (prepared != null) {
        _state = _state.copyWith(
          activeAlerts: remainingAlerts,
          activeAlert: nextAlert,
          dispatchMatch: prepared.dispatchMatch,
          routePlan: prepared.routePlan,
          sosIntensity:
              _state.committedAlertIds.contains(nextAlert.id) ? 1 : 0.35,
          emergencyCommitted: _state.committedAlertIds.contains(nextAlert.id),
        );
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
      clearDispatchMatch: true,
      clearRoutePlan: true,
      sosIntensity: 0,
      emergencyCommitted: false,
    );
    notifyListeners();
  }

  Future<_PreparedEmergency?> _prepareEmergency(EmergencyAlert alert) async {
    final profile = _state.profile;
    if (profile == null) return null;

    final isCompatible = BloodCompatibility.canDonateTo(
      donorBloodType: profile.bloodType,
      recipientBloodType: alert.requiredBloodType,
    );
    if (!isCompatible) return null;

    final currentLocation = await _locationService.getCurrentLocation();
    final distanceKm = currentLocation.distanceKmTo(alert.hospitalLocation);
    final dispatchMatch = DispatchWavePolicy.evaluate(
      alert: alert,
      donorLocation: currentLocation,
      donorProvinceCode: profile.provinceCode,
    );

    if (!dispatchMatch.isEligible) return null;

    final routePlan = await _routePlannerService.planRoute(
      origin: currentLocation,
      destination: alert.hospitalLocation,
      preferredDistanceKm: distanceKm,
    );

    return _PreparedEmergency(
      dispatchMatch: dispatchMatch,
      routePlan: routePlan,
    );
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}

class _PreparedEmergency {
  const _PreparedEmergency({
    required this.dispatchMatch,
    required this.routePlan,
  });

  final DispatchMatch dispatchMatch;
  final RoutePlan routePlan;
}
