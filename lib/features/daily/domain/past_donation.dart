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
    this.resultSummary,
    this.resultPublishedAt,
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
      resultSummary: json['result_summary'] as String?,
      resultPublishedAt: json['result_published_at'] == null
          ? null
          : DateTime.parse(json['result_published_at'] as String),
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
  final String? resultSummary;
  final DateTime? resultPublishedAt;

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
      'result_summary': resultSummary,
      'result_published_at': resultPublishedAt?.toIso8601String(),
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
