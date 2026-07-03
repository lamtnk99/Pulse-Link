import '../../../core/utils/date_math.dart';

class DonorProfile {
  const DonorProfile({
    required this.id,
    required this.name,
    required this.bloodType,
    required this.heroLevel,
    required this.badgeTitle,
    required this.totalDonations,
    required this.lastDonationDate,
    required this.points,
    required this.provinceCode,
    required this.heroPassCode,
    this.recognition = const DonorRecognition.empty(),
  });

  factory DonorProfile.fromJson(Map<String, dynamic> json) {
    return DonorProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      bloodType: json['blood_type'] as String,
      heroLevel: json['hero_level'] as String,
      badgeTitle: json['badge_title'] as String,
      totalDonations: json['total_donations'] as int,
      lastDonationDate: DateTime.parse(json['last_donation_date'] as String),
      points: json['points'] as int,
      provinceCode: json['province_code'] as String,
      heroPassCode: json['hero_pass_code'] as String,
      recognition: DonorRecognition.fromJson(
        json['recognition'] as Map<String, dynamic>?,
      ),
    );
  }

  final String id;
  final String name;
  final String bloodType;
  final String heroLevel;
  final String badgeTitle;
  final int totalDonations;
  final DateTime lastDonationDate;
  final int points;
  final String provinceCode;
  final String heroPassCode;
  final DonorRecognition recognition;

  DateTime get nextEligibleDate {
    return lastDonationDate.add(const Duration(days: 84));
  }

  int daysUntilEligible(DateTime now) {
    return DateMath.daysLeftUntil(target: nextEligibleDate, now: now);
  }

  double recoveryProgress(DateTime now) {
    final daysPassed = now.difference(lastDonationDate).inDays.clamp(0, 84);
    return daysPassed.toDouble() / 84;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'blood_type': bloodType,
      'hero_level': heroLevel,
      'badge_title': badgeTitle,
      'total_donations': totalDonations,
      'last_donation_date': lastDonationDate.toIso8601String(),
      'points': points,
      'province_code': provinceCode,
      'hero_pass_code': heroPassCode,
      'recognition': recognition.toJson(),
    };
  }

  DonorProfile copyWith({
    String? id,
    String? name,
    String? bloodType,
    String? heroLevel,
    String? badgeTitle,
    int? totalDonations,
    DateTime? lastDonationDate,
    int? points,
    String? provinceCode,
    String? heroPassCode,
    DonorRecognition? recognition,
  }) {
    return DonorProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      bloodType: bloodType ?? this.bloodType,
      heroLevel: heroLevel ?? this.heroLevel,
      badgeTitle: badgeTitle ?? this.badgeTitle,
      totalDonations: totalDonations ?? this.totalDonations,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      points: points ?? this.points,
      provinceCode: provinceCode ?? this.provinceCode,
      heroPassCode: heroPassCode ?? this.heroPassCode,
      recognition: recognition ?? this.recognition,
    );
  }
}

class DonorRecognition {
  const DonorRecognition({
    required this.level,
    required this.badgeTitle,
    required this.totalDonations,
    required this.totalVolumeMl,
    required this.sosDonations,
    required this.points,
    required this.globalRank,
    required this.provinceRank,
    required this.badges,
  });

  const DonorRecognition.empty()
      : level = '',
        badgeTitle = '',
        totalDonations = 0,
        totalVolumeMl = 0,
        sosDonations = 0,
        points = 0,
        globalRank = 0,
        provinceRank = 0,
        badges = const [];

  factory DonorRecognition.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DonorRecognition.empty();

    return DonorRecognition(
      level: json['level'] as String? ?? '',
      badgeTitle: json['badge_title'] as String? ?? '',
      totalDonations: json['total_donations'] as int? ?? 0,
      totalVolumeMl: json['total_volume_ml'] as int? ?? 0,
      sosDonations: json['sos_donations'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      globalRank: json['global_rank'] as int? ?? 0,
      provinceRank: json['province_rank'] as int? ?? 0,
      badges: (json['badges'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(DonorBadge.fromJson)
          .toList(growable: false),
    );
  }

  final String level;
  final String badgeTitle;
  final int totalDonations;
  final int totalVolumeMl;
  final int sosDonations;
  final int points;
  final int globalRank;
  final int provinceRank;
  final List<DonorBadge> badges;

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'badge_title': badgeTitle,
      'total_donations': totalDonations,
      'total_volume_ml': totalVolumeMl,
      'sos_donations': sosDonations,
      'points': points,
      'global_rank': globalRank,
      'province_rank': provinceRank,
      'badges': badges.map((badge) => badge.toJson()).toList(growable: false),
    };
  }
}

class DonorBadge {
  const DonorBadge({
    required this.code,
    required this.name,
    required this.description,
  });

  factory DonorBadge.fromJson(Map<String, dynamic> json) {
    return DonorBadge(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  final String code;
  final String name;
  final String description;

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
    };
  }
}
