import '../features/daily/domain/donation_event.dart';
import '../features/daily/domain/donation_appointment.dart';
import '../core/location/geo_point.dart';

abstract interface class DonationEventRepository {
  Future<List<DonationEvent>> getUpcomingEvents({GeoPoint? origin});

  Future<DonationEvent> getEventDetail(String eventId, {GeoPoint? origin});

  Future<List<DonationAppointment>> getBookedAppointments();

  Future<DonationEvent> bookAppointment(String eventId, {GeoPoint? origin});

  Future<DonationEvent> cancelAppointment(String eventId, {GeoPoint? origin});
}
