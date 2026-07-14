import 'blood_journey.dart';

class PastDonation {
  const PastDonation({
    required this.id,
    required this.donatedAt,
    required this.locationName,
    required this.volumeMl,
    required this.bloodType,
    required this.certificateId,
    required this.status,
    this.donationType = DonationType.regular,
    this.certificateTitle,
    this.certificateIssuedAt,
    this.certificateVerifyUrl,
    this.notes,
    this.gratitudeMessage,
    this.gratitudeStyle,
    this.gratitudeCreatedAt,
    this.resultSummary,
    this.resultPublishedAt,
    this.bloodJourney,
  });

  factory PastDonation.fromJson(Map<String, dynamic> json) {
    return PastDonation(
      id: json['id'] as String,
      donatedAt: DateTime.parse(json['donated_at'] as String),
      locationName: json['location_name'] as String,
      volumeMl: json['volume_ml'] as int,
      bloodType: json['blood_type'] as String,
      certificateId: json['certificate_id'] as String,
      status:
          DonationVerificationStatus.values.byName(json['status'] as String),
      donationType: DonationType.fromJson(json['donation_type'] as String?),
      certificateTitle: json['certificate_title'] as String?,
      certificateIssuedAt: json['certificate_issued_at'] == null
          ? null
          : DateTime.parse(json['certificate_issued_at'] as String),
      certificateVerifyUrl: json['certificate_verify_url'] as String?,
      notes: json['notes'] as String?,
      gratitudeMessage: json['gratitude_message'] as String?,
      gratitudeStyle: json['gratitude_style'] as String?,
      gratitudeCreatedAt: json['gratitude_created_at'] == null
          ? null
          : DateTime.tryParse(json['gratitude_created_at'] as String),
      resultSummary: json['result_summary'] as String?,
      resultPublishedAt: json['result_published_at'] == null
          ? null
          : DateTime.parse(json['result_published_at'] as String),
      bloodJourney: json['blood_journey'] is Map<String, dynamic>
          ? BloodJourney.fromJson(json['blood_journey'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final DateTime donatedAt;
  final String locationName;
  final int volumeMl;
  final String bloodType;
  final String certificateId;
  final DonationVerificationStatus status;
  final DonationType donationType;
  final String? certificateTitle;
  final DateTime? certificateIssuedAt;
  final String? certificateVerifyUrl;
  final String? notes;
  final String? gratitudeMessage;
  final String? gratitudeStyle;
  final DateTime? gratitudeCreatedAt;
  final String? resultSummary;
  final DateTime? resultPublishedAt;
  final BloodJourney? bloodJourney;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donated_at': donatedAt.toIso8601String(),
      'location_name': locationName,
      'volume_ml': volumeMl,
      'blood_type': bloodType,
      'certificate_id': certificateId,
      'status': status.name,
      'donation_type': donationType.name,
      'certificate_title': certificateTitle,
      'certificate_issued_at': certificateIssuedAt?.toIso8601String(),
      'certificate_verify_url': certificateVerifyUrl,
      'notes': notes,
      'gratitude_message': gratitudeMessage,
      'gratitude_style': gratitudeStyle,
      'gratitude_created_at': gratitudeCreatedAt?.toIso8601String(),
      'result_summary': resultSummary,
      'result_published_at': resultPublishedAt?.toIso8601String(),
      'blood_journey': bloodJourney,
    };
  }
}

class PastDonationDraft {
  const PastDonationDraft({
    required this.donatedAt,
    required this.locationName,
    required this.volumeMl,
    required this.bloodType,
    this.notes,
  });

  final DateTime donatedAt;
  final String locationName;
  final int volumeMl;
  final String bloodType;
  final String? notes;
}

enum DonationVerificationStatus {
  pending,
  verified,
}

enum DonationType {
  regular,
  sos,
  manual;

  static DonationType fromJson(String? value) {
    return DonationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => DonationType.regular,
    );
  }
}
