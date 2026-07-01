import '../core/enums/app_mode.dart';
import '../features/community/domain/community_post.dart';
import '../features/daily/domain/donation_appointment.dart';
import '../features/daily/domain/donation_event.dart';
import '../features/daily/domain/past_donation.dart';
import '../features/emergency/domain/dispatch_wave.dart';
import '../features/emergency/domain/emergency_alert.dart';
import '../features/emergency/domain/route_plan.dart';
import '../features/profile/domain/donor_profile.dart';

class PulseLinkState {
  const PulseLinkState({
    required this.activeMode,
    required this.isLoading,
    this.profile,
    this.events = const [],
    this.bookedAppointments = const [],
    this.communityPosts = const [],
    this.donationHistory = const [],
    this.activeAlert,
    this.dispatchMatch,
    this.routePlan,
    this.sosIntensity = 0,
    this.emergencyCommitted = false,
  });

  factory PulseLinkState.initial() {
    return const PulseLinkState(
      activeMode: AppMode.daily,
      isLoading: true,
    );
  }

  final AppMode activeMode;
  final bool isLoading;
  final DonorProfile? profile;
  final List<DonationEvent> events;
  final List<DonationAppointment> bookedAppointments;
  final List<CommunityPost> communityPosts;
  final List<PastDonation> donationHistory;
  final EmergencyAlert? activeAlert;
  final DispatchMatch? dispatchMatch;
  final RoutePlan? routePlan;
  final double sosIntensity;
  final bool emergencyCommitted;

  int get totalVolumeMl {
    return donationHistory.fold<int>(
      0,
      (total, item) => total + item.volumeMl,
    );
  }

  PulseLinkState copyWith({
    AppMode? activeMode,
    bool? isLoading,
    DonorProfile? profile,
    List<DonationEvent>? events,
    List<DonationAppointment>? bookedAppointments,
    List<CommunityPost>? communityPosts,
    List<PastDonation>? donationHistory,
    EmergencyAlert? activeAlert,
    bool clearActiveAlert = false,
    DispatchMatch? dispatchMatch,
    bool clearDispatchMatch = false,
    RoutePlan? routePlan,
    bool clearRoutePlan = false,
    double? sosIntensity,
    bool? emergencyCommitted,
  }) {
    return PulseLinkState(
      activeMode: activeMode ?? this.activeMode,
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      events: events ?? this.events,
      bookedAppointments: bookedAppointments ?? this.bookedAppointments,
      communityPosts: communityPosts ?? this.communityPosts,
      donationHistory: donationHistory ?? this.donationHistory,
      activeAlert: clearActiveAlert ? null : activeAlert ?? this.activeAlert,
      dispatchMatch:
          clearDispatchMatch ? null : dispatchMatch ?? this.dispatchMatch,
      routePlan: clearRoutePlan ? null : routePlan ?? this.routePlan,
      sosIntensity: sosIntensity ?? this.sosIntensity,
      emergencyCommitted: emergencyCommitted ?? this.emergencyCommitted,
    );
  }
}
