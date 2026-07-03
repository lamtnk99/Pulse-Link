import 'donation_event.dart';

class DonationAppointment {
  const DonationAppointment({
    required this.id,
    required this.status,
    required this.event,
    this.bookedAt,
    this.checkedInAt,
    this.cancelledAt,
    this.completedAt,
    this.noShowAt,
    this.cancelReason,
    this.volumeMl,
    this.screeningStatus,
    this.resultSummary,
    this.resultPublishedAt,
  });

  factory DonationAppointment.fromJson(Map<String, dynamic> json) {
    return DonationAppointment(
      id: json['id'] as String,
      status: DonationAppointmentStatus.fromWireName(json['status'] as String),
      bookedAt: json['booked_at'] == null
          ? null
          : DateTime.parse(json['booked_at'] as String),
      checkedInAt: json['checked_in_at'] == null
          ? null
          : DateTime.parse(json['checked_in_at'] as String),
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.parse(json['cancelled_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      noShowAt: json['no_show_at'] == null
          ? null
          : DateTime.parse(json['no_show_at'] as String),
      cancelReason: json['cancel_reason'] as String?,
      volumeMl: json['volume_ml'] as int?,
      screeningStatus: json['screening_status'] as String?,
      resultSummary: json['result_summary'] as String?,
      resultPublishedAt: json['result_published_at'] == null
          ? null
          : DateTime.parse(json['result_published_at'] as String),
      event: DonationEvent.fromJson(json['event'] as Map<String, dynamic>),
    );
  }

  final String id;
  final DonationAppointmentStatus status;
  final DateTime? bookedAt;
  final DateTime? checkedInAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final DateTime? noShowAt;
  final String? cancelReason;
  final int? volumeMl;
  final String? screeningStatus;
  final String? resultSummary;
  final DateTime? resultPublishedAt;
  final DonationEvent event;

  bool get canCancel => status == DonationAppointmentStatus.booked;
}

enum DonationAppointmentStatus {
  booked('booked'),
  cancelled('cancelled'),
  checkedIn('checked_in'),
  deferred('deferred'),
  completed('completed'),
  noShow('no_show');

  const DonationAppointmentStatus(this.wireName);

  final String wireName;

  static DonationAppointmentStatus fromWireName(String value) {
    return values.firstWhere(
      (status) => status.wireName == value,
      orElse: () => DonationAppointmentStatus.booked,
    );
  }
}
