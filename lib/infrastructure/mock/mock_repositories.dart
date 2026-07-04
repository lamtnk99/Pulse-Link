import 'package:uuid/uuid.dart';

import '../../core/location/geo_point.dart';
import '../../features/community/domain/community_post.dart';
import '../../features/daily/domain/donation_appointment.dart';
import '../../features/daily/domain/donation_event.dart';
import '../../features/daily/domain/past_donation.dart';
import '../../features/profile/domain/donor_profile.dart';
import '../../services/donation_event_repository.dart';
import '../../services/donation_history_repository.dart';
import '../../services/donor_repository.dart';
import '../../services/community_post_repository.dart';
import '../../services/chat_service.dart';
import '../../features/chat/domain/chat_conversation.dart';
import '../../features/chat/domain/chat_message.dart';
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
  Future<List<DonationEvent>> getUpcomingEvents({GeoPoint? origin}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final events = _events
        .map(
          (event) => origin == null
              ? event
              : event.copyWith(distanceKm: origin.distanceKmTo(event.location)),
        )
        .toList(growable: false)
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return List<DonationEvent>.unmodifiable(events);
  }

  @override
  Future<DonationEvent> getEventDetail(String eventId,
      {GeoPoint? origin}) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final event = _events.firstWhere((event) => event.id == eventId);
    return origin == null
        ? event
        : event.copyWith(distanceKm: origin.distanceKmTo(event.location));
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
  Future<DonationEvent> bookAppointment(String eventId,
      {GeoPoint? origin}) async {
    return _setBooking(eventId: eventId, booked: true, origin: origin);
  }

  @override
  Future<DonationEvent> cancelAppointment(String eventId,
      {GeoPoint? origin}) async {
    return _setBooking(eventId: eventId, booked: false, origin: origin);
  }

  Future<DonationEvent> _setBooking({
    required String eventId,
    required bool booked,
    GeoPoint? origin,
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
    return origin == null
        ? updated
        : updated.copyWith(distanceKm: origin.distanceKmTo(updated.location));
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

class MockChatService implements ChatService {
  final List<ChatConversation> _conversations = [];
  final Map<String, List<ChatMessage>> _messages = {};

  @override
  Future<List<ChatConversation>> getConversations() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _conversations;
  }

  @override
  Future<ChatConversation> getConversation(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final conversation = _conversations.firstWhere((c) => c.id == id);
    return ChatConversation(
      id: conversation.id,
      title: conversation.title,
      contextType: conversation.contextType,
      contextMeta: conversation.contextMeta,
      isActive: conversation.isActive,
      createdAt: conversation.createdAt,
      messages: _messages[id] ?? [],
    );
  }

  @override
  Future<ChatConversation> createConversation({
    String? contextType,
    Map<String, dynamic>? contextMeta,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final conversation = ChatConversation(
      id: id,
      title: 'Cuộc trò chuyện mới',
      contextType: contextType ?? 'general',
      contextMeta: contextMeta,
      isActive: true,
      createdAt: DateTime.now(),
    );
    _conversations.insert(0, conversation);
    _messages[id] = [];
    return conversation;
  }

  @override
  Future<ChatMessage> sendMessage(String conversationId, String content) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
    );
    _messages[conversationId] ??= [];
    _messages[conversationId]!.add(userMsg);

    // AI reply
    await Future.delayed(const Duration(milliseconds: 600));
    String replyContent = 'Chào bạn! Đây là câu trả lời thử nghiệm từ trợ lý sức khỏe Mock AI của Pulse Link. ';
    if (content.toLowerCase().contains('chóng mặt') || content.toLowerCase().contains('mệt')) {
      replyContent += 'Nếu bạn cảm thấy chóng mặt hoặc mệt mỏi sau khi hiến máu, hãy nằm nghỉ ngay lập tức, uống nhiều nước ấm và tránh vận động mạnh trong 24 giờ. Nếu triệu chứng không thuyên giảm, vui lòng liên hệ hotline 115.';
    } else {
      replyContent += 'Tôi có thể hỗ trợ giải đáp các thắc mắc về dinh dưỡng, tập luyện và hướng dẫn tự chăm sóc sức khỏe sau hiến máu.';
    }

    final aiMsg = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      role: 'assistant',
      content: replyContent,
      createdAt: DateTime.now(),
    );
    _messages[conversationId]!.add(aiMsg);

    // Update conversation title
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final prev = _conversations[idx];
      _conversations[idx] = ChatConversation(
        id: prev.id,
        title: content.length > 25 ? '${content.substring(0, 22)}...' : content,
        contextType: prev.contextType,
        contextMeta: prev.contextMeta,
        isActive: prev.isActive,
        createdAt: prev.createdAt,
        latestMessage: aiMsg,
      );
    }

    return aiMsg;
  }

  @override
  Future<ChatConversation?> getActiveCheckup() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _conversations.indexWhere((c) => c.contextType == 'post_donation_checkup' && c.isActive);
    if (idx == -1) return null;
    return _conversations[idx];
  }

  @override
  Future<Map<String, dynamic>> getQuota() async {
    return {
      'used': 0,
      'limit': 0,
      'remaining': -1,
    };
  }
}
