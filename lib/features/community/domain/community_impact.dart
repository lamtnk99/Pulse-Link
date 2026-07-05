/// Số liệu tác động tập thể + tường tri ân của cộng đồng Pulse Link.
class CommunityImpact {
  const CommunityImpact({
    required this.monthLabel,
    required this.donationsThisMonth,
    required this.volumeMlThisMonth,
    required this.activeDonors,
    required this.livesTouched,
    required this.totalHeroCount,
    required this.gratitudeWall,
  });

  factory CommunityImpact.fromJson(Map<String, dynamic> json) {
    return CommunityImpact(
      monthLabel: json['month_label'] as String? ?? '',
      donationsThisMonth: (json['donations_this_month'] as num?)?.toInt() ?? 0,
      volumeMlThisMonth: (json['volume_ml_this_month'] as num?)?.toInt() ?? 0,
      activeDonors: (json['active_donors'] as num?)?.toInt() ?? 0,
      livesTouched: (json['lives_touched'] as num?)?.toInt() ?? 0,
      totalHeroCount: (json['total_hero_count'] as num?)?.toInt() ?? 0,
      gratitudeWall: (json['gratitude_wall'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GratitudeNote.fromJson)
          .toList(growable: false),
    );
  }

  final String monthLabel;
  final int donationsThisMonth;
  final int volumeMlThisMonth;
  final int activeDonors;
  final int livesTouched;
  final int totalHeroCount;
  final List<GratitudeNote> gratitudeWall;

  bool get hasData => donationsThisMonth > 0 || activeDonors > 0 || gratitudeWall.isNotEmpty;
}

/// Một lời chúc trên tường tri ân cộng đồng.
class GratitudeNote {
  const GratitudeNote({
    required this.donorName,
    required this.message,
    this.isAnonymous = false,
  });

  factory GratitudeNote.fromJson(Map<String, dynamic> json) {
    return GratitudeNote(
      donorName: json['donor_name'] as String? ?? 'Hiệp sĩ ẩn danh',
      message: json['message'] as String? ?? '',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
    );
  }

  final String donorName;
  final String message;
  final bool isAnonymous;
}
