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
import '../../services/donation_fund_service.dart';
import '../../features/donation/domain/donation_campaign.dart';
import '../../features/donation/domain/campaign_donation.dart';
import '../../services/community_impact_service.dart';
import '../../features/community/domain/community_impact.dart';
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

  @override
  Future<void> updateBaseLocation(GeoPoint location) async {
    // No-op for mock repository
  }

  @override
  Future<DonorProfile> updateProfile(Map<String, dynamic> fields) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final submittingId = (fields['national_id'] as String?)?.isNotEmpty ?? false;
    final hasBothImages = (fields['id_card_front_url'] as String?)?.isNotEmpty == true &&
        (fields['id_card_back_url'] as String?)?.isNotEmpty == true;
    _profile = _profile.copyWith(
      name: fields['name'] as String?,
      phone: fields['phone'] as String?,
      bloodType: fields['blood_type'] as String?,
      dateOfBirth: fields['date_of_birth'] as String?,
      gender: fields['gender'] as String?,
      address: fields['address'] as String?,
      provinceCode: fields['province_code'] as String?,
      wardCode: fields['ward_code'] as String?,
      nationalId: fields['national_id'] as String?,
      idCardFrontUrl: fields['id_card_front_url'] as String?,
      idCardBackUrl: fields['id_card_back_url'] as String?,
      idVerificationStatus: submittingId && hasBothImages ? 'pending' : null,
    );
    return _profile;
  }

  @override
  Future<String> uploadIdImage(List<int> bytes, String filename) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return 'https://mock.pulselink.test/id-cards/${Uri.encodeComponent(filename)}';
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

class MockDonationFundService implements DonationFundService {
  final List<DonationCampaign> _campaigns = [
    DonationCampaign(
      id: 'mock-campaign-1',
      title: 'Quỹ Cấp Cứu SOS Bệnh Nhân Nghèo',
      description: 'Hỗ trợ viện phí và chi phí truyền máu khẩn cấp cho các hoàn cảnh khó khăn tại bệnh viện Đa Khoa tỉnh.',
      imageUrl: 'https://images.unsplash.com/photo-1576091160550-2173dba999ef',
      targetAmount: 50000000.0,
      currentAmount: 35000000.0,
      status: 'active',
      beneficiaryName: 'Bé Gia Bảo, 6 tuổi',
      beneficiaryStory:
          'Gia Bảo mắc bệnh tan máu bẩm sinh, mỗi tháng em cần truyền máu để duy trì sự sống. Ba làm phụ hồ, mẹ bán vé số, khoản viện phí hơn 8 triệu mỗi đợt vượt xa sức của gia đình. "Con chỉ mong được đi học lại với các bạn" — Gia Bảo nói khi nằm trên giường bệnh.',
      impactUnit: 'ngày điều trị',
      impactPerUnitAmount: 250000,
      urgencyLevel: 'critical',
      donorCount: 128,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      expiresAt: DateTime.now().add(const Duration(days: 12)),
    ),
    DonationCampaign(
      id: 'mock-campaign-2',
      title: 'Hành Trình Đỏ 2026 - Bản Cao',
      description: 'Chiến dịch mang các phần quà dinh dưỡng và trang bị y tế đến các điểm trường vùng sâu vùng xa.',
      imageUrl: 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c',
      targetAmount: 30000000.0,
      currentAmount: 18000000.0,
      status: 'active',
      beneficiaryName: 'Điểm trường Lũng Cú, Hà Giang',
      beneficiaryStory:
          'Điểm trường có 42 em nhỏ, cách trạm y tế gần nhất hơn 15km đường núi. Mùa lũ về, một vết thương nhỏ cũng có thể trở nên nguy hiểm khi không có bông băng, thuốc sát trùng. Điểm Hero bạn tích lũy nay có thể hóa thành một tủ thuốc thật đặt ngay tại lớp học.',
      impactUnit: 'bộ sơ cứu',
      impactPerUnitAmount: 50000,
      urgencyLevel: 'normal',
      donorCount: 54,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    )
  ];

  final Map<String, List<CampaignDonation>> _leaderboards = {
    'mock-campaign-1': [
      CampaignDonation(donorName: 'Nguyễn Văn An', amount: 5000000.0, points: 200, message: 'Chúc bé mau khỏe, cố lên con nhé!', lastDonatedAt: DateTime.now()),
      CampaignDonation(donorName: 'Hiệp sĩ ẩn danh', amount: 2000000.0, points: 50, message: 'Mong ca điều trị thật thuận lợi.', isAnonymous: true, lastDonatedAt: DateTime.now()),
      CampaignDonation(donorName: 'Trần Thị Bình', amount: 1500000.0, points: 100, lastDonatedAt: DateTime.now()),
    ],
    'mock-campaign-2': [
      CampaignDonation(donorName: 'Lê Văn Cường', amount: 0, points: 1500, message: 'Gửi chút hơi ấm tới các em vùng cao.', lastDonatedAt: DateTime.now()),
      CampaignDonation(donorName: 'Hiệp sĩ ẩn danh', amount: 0, points: 1000, isAnonymous: true, lastDonatedAt: DateTime.now()),
      CampaignDonation(donorName: 'Nguyễn Thị Dung', amount: 0, points: 800, message: 'Lan tỏa yêu thương đến mọi người.', lastDonatedAt: DateTime.now()),
    ],
  };

  @override
  Future<List<DonationCampaign>> getCampaigns() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _campaigns;
  }

  @override
  Future<Map<String, dynamic>> getCampaignDetail(String campaignId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final campaign = _campaigns.firstWhere((c) => c.id == campaignId);
    return {
      'campaign': campaign,
      'leaderboard': _leaderboards[campaignId] ?? [],
    };
  }

  @override
  Future<Map<String, dynamic>> donateCash({
    required String campaignId,
    required double amount,
    required String paymentMethod,
    String? donorName,
    String? message,
    bool isAnonymous = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return {
      'donation_id': 999,
      'transaction_id': 'TXN-MOCK123456',
      'payment_url': 'http://127.0.0.1:8000/mock-payment/TXN-MOCK123456',
    };
  }

  @override
  Future<Map<String, dynamic>> donatePoints({
    required String campaignId,
    required int points,
    String? donorName,
    String? message,
    bool isAnonymous = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _campaigns.indexWhere((c) => c.id == campaignId);
    if (idx != -1) {
      final prev = _campaigns[idx];
      _campaigns[idx] = DonationCampaign(
        id: prev.id,
        title: prev.title,
        description: prev.description,
        imageUrl: prev.imageUrl,
        targetAmount: prev.targetAmount,
        // Điểm quy đổi thẳng ra VND rồi gộp vào cùng trục tiền.
        currentAmount: prev.currentAmount + prev.amountFromPoints(points),
        pointValueVnd: prev.pointValueVnd,
        status: prev.status,
        beneficiaryName: prev.beneficiaryName,
        beneficiaryStory: prev.beneficiaryStory,
        impactUnit: prev.impactUnit,
        impactPerUnitAmount: prev.impactPerUnitAmount,
        urgencyLevel: prev.urgencyLevel,
        donorCount: prev.donorCount + 1,
        createdAt: prev.createdAt,
        expiresAt: prev.expiresAt,
      );
    }
    return {
      'donation_id': 999,
      'remaining_points': 500,
    };
  }

  @override
  Future<String> checkTransactionStatus(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return 'success';
  }
}

class MockCommunityImpactService implements CommunityImpactService {
  @override
  Future<CommunityImpact> getImpact() async {
    await Future.delayed(const Duration(milliseconds: 120));
    return const CommunityImpact(
      monthLabel: 'Tháng này',
      donationsThisMonth: 342,
      volumeMlThisMonth: 119700,
      activeDonors: 289,
      livesTouched: 1026,
      totalHeroCount: 1580,
      campaignDonationsCount: 156,
      totalDonatedAmount: 78000000.0,
      gratitudeWall: [
        GratitudeNote(donorName: 'Nguyễn Hoài An', message: 'Cho đi một chút, nhận lại rất nhiều bình yên trong lòng.'),
        GratitudeNote(donorName: 'Hiệp sĩ ẩn danh', message: 'Mong người bệnh mau khỏe, cố lên nhé!', isAnonymous: true),
        GratitudeNote(donorName: 'Trần Minh Quân', message: 'Lần đầu hiến máu, hồi hộp mà vui lắm.'),
        GratitudeNote(donorName: 'Phạm Thanh Vy', message: 'Hẹn gặp lại mọi người ở lần hiến sau nhé.'),
      ],
    );
  }
}
