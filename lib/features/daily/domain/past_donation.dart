class PastDonation {
  const PastDonation({
    required this.id,
    required this.donatedAt,
    required this.locationName,
    required this.volumeMl,
    required this.bloodType,
    required this.certificateId,
    required this.status,
    this.notes,
  });

  factory PastDonation.fromJson(Map<String, dynamic> json) {
    return PastDonation(
      id: json['id'] as String,
      donatedAt: DateTime.parse(json['donated_at'] as String),
      locationName: json['location_name'] as String,
      volumeMl: json['volume_ml'] as int,
      bloodType: json['blood_type'] as String,
      certificateId: json['certificate_id'] as String,
      status: DonationVerificationStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final DateTime donatedAt;
  final String locationName;
  final int volumeMl;
  final String bloodType;
  final String certificateId;
  final DonationVerificationStatus status;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donated_at': donatedAt.toIso8601String(),
      'location_name': locationName,
      'volume_ml': volumeMl,
      'blood_type': bloodType,
      'certificate_id': certificateId,
      'status': status.name,
      'notes': notes,
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
