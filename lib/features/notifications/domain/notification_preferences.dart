class NotificationPreferences {
  const NotificationPreferences({
    this.sosEnabled = true,
    this.appointmentsEnabled = true,
    this.careEnabled = true,
    this.nearbyEventsEnabled = false,
    this.communityEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      sosEnabled: json['sos_enabled'] as bool? ?? true,
      appointmentsEnabled: json['appointments_enabled'] as bool? ?? true,
      careEnabled: json['care_enabled'] as bool? ?? true,
      nearbyEventsEnabled: json['nearby_events_enabled'] as bool? ?? false,
      communityEnabled: json['community_enabled'] as bool? ?? false,
      quietHoursStart: json['quiet_hours_start'] as String?,
      quietHoursEnd: json['quiet_hours_end'] as String?,
    );
  }

  final bool sosEnabled;
  final bool appointmentsEnabled;
  final bool careEnabled;
  final bool nearbyEventsEnabled;
  final bool communityEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  Map<String, dynamic> toJson() => {
        'sos_enabled': sosEnabled,
        'appointments_enabled': appointmentsEnabled,
        'care_enabled': careEnabled,
        'nearby_events_enabled': nearbyEventsEnabled,
        'community_enabled': communityEnabled,
        'quiet_hours_start': quietHoursStart,
        'quiet_hours_end': quietHoursEnd,
      };

  NotificationPreferences copyWith({
    bool? sosEnabled,
    bool? appointmentsEnabled,
    bool? careEnabled,
    bool? nearbyEventsEnabled,
    bool? communityEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool clearQuietHours = false,
  }) {
    return NotificationPreferences(
      sosEnabled: sosEnabled ?? this.sosEnabled,
      appointmentsEnabled: appointmentsEnabled ?? this.appointmentsEnabled,
      careEnabled: careEnabled ?? this.careEnabled,
      nearbyEventsEnabled: nearbyEventsEnabled ?? this.nearbyEventsEnabled,
      communityEnabled: communityEnabled ?? this.communityEnabled,
      quietHoursStart:
          clearQuietHours ? null : quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd:
          clearQuietHours ? null : quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}
