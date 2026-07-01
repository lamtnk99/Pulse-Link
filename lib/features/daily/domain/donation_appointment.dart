import 'donation_event.dart';

class DonationAppointment {
  const DonationAppointment({
    required this.id,
    required this.status,
    required this.event,
    this.bookedAt,
  });

  factory DonationAppointment.fromJson(Map<String, dynamic> json) {
    return DonationAppointment(
      id: json['id'] as String,
      status: DonationAppointmentStatus.values.byName(json['status'] as String),
      bookedAt: json['booked_at'] == null
          ? null
          : DateTime.parse(json['booked_at'] as String),
      event: DonationEvent.fromJson(json['event'] as Map<String, dynamic>),
    );
  }

  final String id;
  final DonationAppointmentStatus status;
  final DateTime? bookedAt;
  final DonationEvent event;
}

enum DonationAppointmentStatus {
  booked,
  cancelled,
  completed,
  no_show,
}
