import '../../features/community/domain/community_post.dart';
import '../../features/daily/domain/donation_appointment.dart';
import '../../features/daily/domain/donation_event.dart';
import '../../features/daily/domain/past_donation.dart';
import '../../features/profile/domain/donor_profile.dart';
import '../../services/donation_event_repository.dart';
import '../../services/donation_history_repository.dart';
import '../../services/donor_repository.dart';
import '../../services/community_post_repository.dart';
import 'laravel_api_client.dart';

class LaravelDonorRepository implements DonorRepository {
  const LaravelDonorRepository(this._client);

  final LaravelApiClient _client;

  @override
  Future<DonorProfile> getCurrentProfile() async {
    final json = await _client.getJson('/api/mobile/me/hero-pass');
    return DonorProfile.fromJson(_unwrapData(json));
  }

  @override
  Future<void> saveProfile(DonorProfile profile) async {
    await _client.postJson(
      '/api/mobile/me/hero-pass',
      body: profile.toJson(),
    );
  }
}

class LaravelDonationEventRepository implements DonationEventRepository {
  const LaravelDonationEventRepository(this._client);

  final LaravelApiClient _client;

  @override
  Future<List<DonationEvent>> getUpcomingEvents() async {
    final json = await _client.getList('/api/mobile/donation-events');
    return json
        .cast<Map<String, dynamic>>()
        .map(DonationEvent.fromJson)
        .toList(growable: false);
  }

  @override
  Future<DonationEvent> getEventDetail(String eventId) async {
    final json = await _client.getJson('/api/mobile/donation-events/$eventId');
    return DonationEvent.fromJson(_unwrapData(json));
  }

  @override
  Future<List<DonationAppointment>> getBookedAppointments() async {
    final json = await _client.getList('/api/mobile/me/appointments');
    return json
        .cast<Map<String, dynamic>>()
        .map(DonationAppointment.fromJson)
        .toList(growable: false);
  }

  @override
  Future<DonationEvent> bookAppointment(String eventId) async {
    final json = await _client.postJson(
      '/api/mobile/donation-events/$eventId/book',
    );
    return DonationEvent.fromJson(_unwrapData(json));
  }

  @override
  Future<DonationEvent> cancelAppointment(String eventId) async {
    final json = await _client.postJson(
      '/api/mobile/donation-events/$eventId/cancel',
    );
    return DonationEvent.fromJson(_unwrapData(json));
  }
}

class LaravelCommunityPostRepository implements CommunityPostRepository {
  const LaravelCommunityPostRepository(this._client);

  final LaravelApiClient _client;

  @override
  Future<List<CommunityPost>> getPublishedPosts() async {
    final json = await _client.getList('/api/mobile/community-posts');
    return json
        .cast<Map<String, dynamic>>()
        .map(CommunityPost.fromJson)
        .toList(growable: false);
  }

  @override
  Future<CommunityPost> getPostDetail(String slug) async {
    final json = await _client.getJson('/api/mobile/community-posts/$slug');
    return CommunityPost.fromJson(_unwrapData(json));
  }
}

class LaravelDonationHistoryRepository implements DonationHistoryRepository {
  const LaravelDonationHistoryRepository(this._client);

  final LaravelApiClient _client;

  @override
  Future<List<PastDonation>> getDonationHistory() async {
    final json = await _client.getList('/api/mobile/me/donations');
    return json
        .cast<Map<String, dynamic>>()
        .map(PastDonation.fromJson)
        .toList(growable: false);
  }

  @override
  Future<PastDonation> addDonation(PastDonationDraft draft) async {
    final json = await _client.postJson(
      '/api/mobile/me/donations',
      body: {
        'donated_at': draft.donatedAt.toIso8601String(),
        'location_name': draft.locationName,
        'volume_ml': draft.volumeMl,
        'blood_type': draft.bloodType,
        'notes': draft.notes,
      },
    );
    return PastDonation.fromJson(_unwrapData(json));
  }
}

Map<String, dynamic> _unwrapData(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) return data;
  return json;
}
