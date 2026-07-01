import '../features/daily/domain/donation_event.dart';
import '../features/daily/domain/donation_appointment.dart';

abstract interface class DonationEventRepository {
  Future<List<DonationEvent>> getUpcomingEvents();

  Future<DonationEvent> getEventDetail(String eventId);

  Future<List<DonationAppointment>> getBookedAppointments();

  Future<DonationEvent> bookAppointment(String eventId);

  Future<DonationEvent> cancelAppointment(String eventId);
}
