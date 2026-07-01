import 'package:uuid/uuid.dart';

import '../../features/community/domain/community_post.dart';
import '../../features/daily/domain/donation_appointment.dart';
import '../../features/daily/domain/donation_event.dart';
import '../../features/daily/domain/past_donation.dart';
import '../../features/profile/domain/donor_profile.dart';
import '../../services/donation_event_repository.dart';
import '../../services/donation_history_repository.dart';
import '../../services/donor_repository.dart';
import '../../services/community_post_repository.dart';
import 'mock_data.dart';

class MockDonorRepository implements DonorRepository {
  DonorProfile _profile = MockData.donorProfile;

  @override
  Future<DonorProfile> getCurrentProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _profile;
  }

  @override
  Future<void> saveProfile(DonorProfile profile) async {
    _profile = profile;
  }
}

class MockDonationEventRepository implements DonationEventRepository {
  final List<DonationEvent> _events = List<DonationEvent>.of(
    MockData.donationEvents,
  );

  @override
  Future<List<DonationEvent>> getUpcomingEvents() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<DonationEvent>.unmodifiable(_events);
  }

  @override
  Future<DonationEvent> getEventDetail(String eventId) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    return _events.firstWhere((event) => event.id == eventId);
  }

  @override
  Future<List<DonationAppointment>> getBookedAppointments() async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    return _events
        .where((event) => event.booked)
        .map(
          (event) => DonationAppointment(
            id: 'apt-${event.id}',
            status: DonationAppointmentStatus.booked,
            bookedAt: DateTime(2026, 7, 1, 9, 30),
            event: event,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<DonationEvent> bookAppointment(String eventId) async {
    return _setBooking(eventId: eventId, booked: true);
  }

  @override
  Future<DonationEvent> cancelAppointment(String eventId) async {
    return _setBooking(eventId: eventId, booked: false);
  }

  Future<DonationEvent> _setBooking({
    required String eventId,
    required bool booked,
  }) async {
    final index = _events.indexWhere((event) => event.id == eventId);
    if (index == -1) {
      throw StateError('Donation event not found: $eventId');
    }

    final current = _events[index];
    if (current.booked == booked) return current;

    final updated = current.copyWith(
      booked: booked,
      slotsLeft: booked ? current.slotsLeft - 1 : current.slotsLeft + 1,
    );
    _events[index] = updated;
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return updated;
  }
}

class MockCommunityPostRepository implements CommunityPostRepository {
  final List<CommunityPost> _posts = List<CommunityPost>.of(
    MockData.communityPosts,
  );

  @override
  Future<List<CommunityPost>> getPublishedPosts() async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return List<CommunityPost>.unmodifiable(_posts);
  }

  @override
  Future<CommunityPost> getPostDetail(String slug) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _posts.firstWhere((post) => post.slug == slug);
  }
}

class MockDonationHistoryRepository implements DonationHistoryRepository {
  final List<PastDonation> _history = List<PastDonation>.of(
    MockData.donationHistory,
  );
  final Uuid _uuid = const Uuid();

  @override
  Future<List<PastDonation>> getDonationHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List<PastDonation>.unmodifiable(_history);
  }

  @override
  Future<PastDonation> addDonation(PastDonationDraft draft) async {
    final donation = PastDonation(
      id: _uuid.v4(),
      donatedAt: draft.donatedAt,
      locationName: draft.locationName,
      volumeMl: draft.volumeMl,
      bloodType: draft.bloodType,
      certificateId:
          'PL-${draft.donatedAt.year}-${1000 + DateTime.now().millisecond}',
      status: DonationVerificationStatus.verified,
      notes: draft.notes,
    );
    _history.insert(0, donation);
    return donation;
  }
}
