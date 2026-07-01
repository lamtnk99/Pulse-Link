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
    );
  }
}
