import '../core/enums/app_mode.dart';
import '../core/enums/app_theme_preference.dart';
import '../core/location/geo_point.dart';
import '../features/community/domain/community_post.dart';
import '../features/daily/domain/donation_appointment.dart';
import '../features/daily/domain/donation_event.dart';
import '../features/daily/domain/past_donation.dart';
import '../features/daily/domain/blood_journey.dart';
import '../features/emergency/domain/dispatch_wave.dart';
import '../features/emergency/domain/emergency_alert.dart';
import '../features/emergency/domain/emergency_commitment.dart';
import '../features/emergency/domain/route_plan.dart';
import '../features/notifications/domain/mobile_notification.dart';
import '../features/profile/domain/donor_profile.dart';

class PulseLinkState {
  const PulseLinkState({
    required this.activeMode,
    this.themePreference = AppThemePreference.light,
    required this.isLoading,
    this.profile,
    this.events = const [],
    this.bookedAppointments = const [],
    this.communityPosts = const [],
    this.donationHistory = const [],
    this.notifications = const [],
    this.activeAlerts = const [],
    this.activeAlert,
    this.sosMissionPhase = SosMissionPhase.alertPreview,
    this.activeEmergencyCommitment,
    this.emergencyLocation,
    this.locationSyncError,
    this.dispatchMatch,
    this.routePlan,
    this.sosIntensity = 0,
    this.emergencyCommitted = false,
    this.committedAlertIds = const {},
    this.initializationError,
    this.activeLiveBloodJourney,
    this.activeLiveBloodJourneyHospitalName,
    this.activeLiveBloodJourneyBloodType,
    this.pendingLevelUp,
    this.acknowledgedJourneyIds = const {},
  });

  factory PulseLinkState.initial() {
    return const PulseLinkState(
      activeMode: AppMode.daily,
      isLoading: true,
      acknowledgedJourneyIds: {},
    );
  }

  final AppMode activeMode;
  final AppThemePreference themePreference;
  final bool isLoading;
  final DonorProfile? profile;
  final List<DonationEvent> events;
  final List<DonationAppointment> bookedAppointments;
  final List<CommunityPost> communityPosts;
  final List<PastDonation> donationHistory;
  final List<MobileNotification> notifications;
  final List<EmergencyAlert> activeAlerts;
  final EmergencyAlert? activeAlert;
  final SosMissionPhase sosMissionPhase;
  final EmergencyCommitment? activeEmergencyCommitment;
  final GeoPoint? emergencyLocation;
  final String? locationSyncError;
  final DispatchMatch? dispatchMatch;
  final RoutePlan? routePlan;
  final double sosIntensity;
  final bool emergencyCommitted;
  final Set<String> committedAlertIds;
  final String? initializationError;

  // Empathy features: Live Blood Journey Tracking override
  final BloodJourney? activeLiveBloodJourney;
  final String? activeLiveBloodJourneyHospitalName;
  final String? activeLiveBloodJourneyBloodType;

  /// Cấp Hero vừa đạt (giá trị gốc như 'Gold Badge') chờ được ăn mừng toàn màn hình.
  /// Null khi không có gì để celebrate.
  final String? pendingLevelUp;

  final Set<String> acknowledgedJourneyIds;

  bool get hasActiveSosAlert => activeAlerts.any((alert) => alert.active && !alert.isExpired);

  int get totalDonationsCount => donationHistory.length;

  int get totalVolumeMl {
    return donationHistory.fold<int>(
      0,
      (total, item) => total + item.volumeMl,
    );
  }

  PulseLinkState copyWith({
    AppMode? activeMode,
    AppThemePreference? themePreference,
    bool? isLoading,
    DonorProfile? profile,
    List<DonationEvent>? events,
    List<DonationAppointment>? bookedAppointments,
    List<CommunityPost>? communityPosts,
    List<PastDonation>? donationHistory,
    List<MobileNotification>? notifications,
    List<EmergencyAlert>? activeAlerts,
    EmergencyAlert? activeAlert,
    bool clearActiveAlert = false,
    SosMissionPhase? sosMissionPhase,
    EmergencyCommitment? activeEmergencyCommitment,
    bool clearActiveEmergencyCommitment = false,
    GeoPoint? emergencyLocation,
    bool clearEmergencyLocation = false,
    String? locationSyncError,
    bool clearLocationSyncError = false,
    DispatchMatch? dispatchMatch,
    bool clearDispatchMatch = false,
    RoutePlan? routePlan,
    bool clearRoutePlan = false,
    double? sosIntensity,
    bool? emergencyCommitted,
    Set<String>? committedAlertIds,
    String? initializationError,
    bool clearInitializationError = false,
    BloodJourney? activeLiveBloodJourney,
    bool clearActiveLiveBloodJourney = false,
    String? activeLiveBloodJourneyHospitalName,
    bool clearActiveLiveBloodJourneyHospitalName = false,
    String? activeLiveBloodJourneyBloodType,
    bool clearActiveLiveBloodJourneyBloodType = false,
    String? pendingLevelUp,
    bool clearPendingLevelUp = false,
    Set<String>? acknowledgedJourneyIds,
  }) {
    return PulseLinkState(
      activeMode: activeMode ?? this.activeMode,
      themePreference: themePreference ?? this.themePreference,
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      events: events ?? this.events,
      bookedAppointments: bookedAppointments ?? this.bookedAppointments,
      communityPosts: communityPosts ?? this.communityPosts,
      donationHistory: donationHistory ?? this.donationHistory,
      notifications: notifications ?? this.notifications,
      activeAlerts: activeAlerts ?? this.activeAlerts,
      activeAlert: clearActiveAlert ? null : activeAlert ?? this.activeAlert,
      sosMissionPhase: sosMissionPhase ?? this.sosMissionPhase,
      activeEmergencyCommitment: clearActiveEmergencyCommitment
          ? null
          : activeEmergencyCommitment ?? this.activeEmergencyCommitment,
      emergencyLocation: clearEmergencyLocation
          ? null
          : emergencyLocation ?? this.emergencyLocation,
      locationSyncError: clearLocationSyncError
          ? null
          : locationSyncError ?? this.locationSyncError,
      dispatchMatch:
          clearDispatchMatch ? null : dispatchMatch ?? this.dispatchMatch,
      routePlan: clearRoutePlan ? null : routePlan ?? this.routePlan,
      sosIntensity: sosIntensity ?? this.sosIntensity,
      emergencyCommitted: emergencyCommitted ?? this.emergencyCommitted,
      committedAlertIds: committedAlertIds ?? this.committedAlertIds,
      initializationError: clearInitializationError
          ? null
          : initializationError ?? this.initializationError,
      activeLiveBloodJourney: clearActiveLiveBloodJourney
          ? null
          : activeLiveBloodJourney ?? this.activeLiveBloodJourney,
      activeLiveBloodJourneyHospitalName: clearActiveLiveBloodJourneyHospitalName
          ? null
          : activeLiveBloodJourneyHospitalName ?? this.activeLiveBloodJourneyHospitalName,
      activeLiveBloodJourneyBloodType: clearActiveLiveBloodJourneyBloodType
          ? null
          : activeLiveBloodJourneyBloodType ?? this.activeLiveBloodJourneyBloodType,
      pendingLevelUp: clearPendingLevelUp
          ? null
          : pendingLevelUp ?? this.pendingLevelUp,
      acknowledgedJourneyIds: acknowledgedJourneyIds ?? this.acknowledgedJourneyIds,
    );
  }
}

enum SosMissionPhase {
  alertPreview,
  missionActive,
}
