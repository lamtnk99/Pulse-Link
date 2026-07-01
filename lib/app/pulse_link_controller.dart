import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/enums/app_mode.dart';
import '../core/utils/blood_compatibility.dart';
import '../features/community/domain/community_post.dart';
import '../features/daily/domain/donation_event.dart';
import '../features/daily/domain/past_donation.dart';
import '../features/emergency/domain/dispatch_wave.dart';
import '../features/emergency/domain/emergency_alert.dart';
import '../features/profile/domain/donor_profile.dart';
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
  PulseLinkState _state = PulseLinkState.initial();

  PulseLinkState get state => _state;

  Future<void> initialize() async {
    final profile = await _donorRepository.getCurrentProfile();
    final events = await _eventRepository.getUpcomingEvents();
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
    );
    notifyListeners();

    await _alertSubscription?.cancel();
    _alertSubscription = _emergencySignalService
        .watchAlerts(profile: profile)
        .listen(_handleEmergencyAlert);
  }

  Future<void> refreshDailyData() async {
    final profile = await _donorRepository.getCurrentProfile();
    final events = await _eventRepository.getUpcomingEvents();
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
    final updated = event.booked
        ? await _eventRepository.cancelAppointment(event.id)
        : await _eventRepository.bookAppointment(event.id);
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
    return _eventRepository.getEventDetail(eventId);
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
    final profile = _state.profile;
    if (profile == null) return;

    final isCompatible = BloodCompatibility.canDonateTo(
      donorBloodType: profile.bloodType,
      recipientBloodType: alert.requiredBloodType,
    );
    if (!isCompatible) return;

    final currentLocation = await _locationService.getCurrentLocation();
    final distanceKm = currentLocation.distanceKmTo(alert.hospitalLocation);
    final dispatchMatch = DispatchWavePolicy.evaluate(
      alert: alert,
      donorLocation: currentLocation,
      donorProvinceCode: profile.provinceCode,
    );

    if (!dispatchMatch.isEligible) return;

    final routePlan = await _routePlannerService.planRoute(
      origin: currentLocation,
      destination: alert.hospitalLocation,
      preferredDistanceKm: distanceKm,
    );

    await _audioService.startHeartbeat(intensity: 0.35);

    _state = _state.copyWith(
      activeMode: AppMode.sos,
      activeAlert: alert,
      dispatchMatch: dispatchMatch,
      routePlan: routePlan,
      sosIntensity: 0.35,
      emergencyCommitted: false,
    );
    notifyListeners();
  }

  Future<void> commitToEmergency() async {
    final alert = _state.activeAlert;
    if (alert == null) return;

    await _emergencySignalService.confirmCommitment(alertId: alert.id);
    await _audioService.confirmedPulse();

    _state = _state.copyWith(
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
    await _audioService.stop();
    _state = _state.copyWith(
      activeMode: AppMode.daily,
      clearActiveAlert: true,
      clearDispatchMatch: true,
      clearRoutePlan: true,
      sosIntensity: 0,
      emergencyCommitted: false,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
