import '../../../core/location/geo_point.dart';

class EmergencyCommitment {
  const EmergencyCommitment({
    required this.id,
    required this.alertId,
    required this.status,
    this.cancelReason,
    this.location,
    this.etaMinutes,
    this.donationVolumeMl,
    this.committedAt,
    this.lastLocationAt,
    this.donatedAt,
  });

  factory EmergencyCommitment.fromJson(Map<String, dynamic> json) {
    final latitude = json['latitude'];
    final longitude = json['longitude'];

    return EmergencyCommitment(
      id: (json['id'] as Object).toString(),
      alertId: json['alert_id'] as String? ?? '',
      status: EmergencyCommitmentStatus.fromName(
        json['status'] as String? ?? 'committed',
      ),
      cancelReason: json['cancel_reason'] as String?,
      location: latitude is num && longitude is num
          ? GeoPoint(
              latitude: latitude.toDouble(),
              longitude: longitude.toDouble(),
            )
          : null,
      etaMinutes: json['eta_minutes'] as int?,
      donationVolumeMl: json['donation_volume_ml'] as int?,
      committedAt: _parseDate(json['committed_at']),
      lastLocationAt: _parseDate(json['last_location_at']),
      donatedAt: _parseDate(json['donated_at']),
    );
  }

  final String id;
  final String alertId;
  final EmergencyCommitmentStatus status;
  final String? cancelReason;
  final GeoPoint? location;
  final int? etaMinutes;
  final int? donationVolumeMl;
  final DateTime? committedAt;
  final DateTime? lastLocationAt;
  final DateTime? donatedAt;

  EmergencyCommitment copyWith({
    EmergencyCommitmentStatus? status,
    String? cancelReason,
    bool clearCancelReason = false,
    GeoPoint? location,
    int? etaMinutes,
    int? donationVolumeMl,
    DateTime? lastLocationAt,
  }) {
    return EmergencyCommitment(
      id: id,
      alertId: alertId,
      status: status ?? this.status,
      cancelReason:
          clearCancelReason ? null : cancelReason ?? this.cancelReason,
      location: location ?? this.location,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      donationVolumeMl: donationVolumeMl ?? this.donationVolumeMl,
      committedAt: committedAt,
      lastLocationAt: lastLocationAt ?? this.lastLocationAt,
      donatedAt: donatedAt,
    );
  }
}

enum EmergencyCommitmentStatus {
  committed,
  enRoute,
  donated,
  cancelled;

  static EmergencyCommitmentStatus fromName(String name) {
    return switch (name) {
      'en_route' => EmergencyCommitmentStatus.enRoute,
      'donated' => EmergencyCommitmentStatus.donated,
      'cancelled' => EmergencyCommitmentStatus.cancelled,
      _ => EmergencyCommitmentStatus.committed,
    };
  }

  String get apiName {
    return switch (this) {
      EmergencyCommitmentStatus.committed => 'committed',
      EmergencyCommitmentStatus.enRoute => 'en_route',
      EmergencyCommitmentStatus.donated => 'donated',
      EmergencyCommitmentStatus.cancelled => 'cancelled',
    };
  }
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
