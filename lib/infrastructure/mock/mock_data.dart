import '../../core/location/geo_point.dart';
import '../../features/community/domain/community_post.dart';
import '../../features/daily/domain/donation_appointment.dart';
import '../../features/daily/domain/donation_event.dart';
import '../../features/daily/domain/past_donation.dart';
import '../../features/emergency/domain/emergency_alert.dart';
import '../../features/profile/domain/donor_profile.dart';

class MockData {
  const MockData._();

  static final donorProfile = DonorProfile(
    id: 'donor-8890',
    name: 'Trần Minh Quân',
    bloodType: 'O+',
    heroLevel: 'Silver Badge',
    badgeTitle: 'Hiệp Sĩ Bạc',
    totalDonations: 5,
    lastDonationDate: DateTime(2026, 4, 15),
    points: 1250,
    provinceCode: '79',
    heroPassCode: 'PL-8890-MINHTRI',
  );

  static final donationEvents = <DonationEvent>[
    DonationEvent(
      id: 'ev-1',
      title: 'Chủ Nhật Đỏ - FPT Polytechnic',
      organizer: 'Hội Chữ thập đỏ TP.HCM',
      description:
          'Điểm hiến máu lưu động dành cho sinh viên và cư dân khu vực Quận 12. Người tham gia nên ăn nhẹ, uống đủ nước và mang giấy tờ tùy thân.',
      startsAt: DateTime(2026, 7, 5, 7, 30),
      endsAt: DateTime(2026, 7, 5, 11, 30),
      locationName: 'Công viên phần mềm Quang Trung, Quận 12',
      location: const GeoPoint(latitude: 10.8521, longitude: 106.6297),
      distanceKm: 1.2,
      urgency: EventUrgency.high,
      imageUrl:
          'https://images.unsplash.com/photo-1615461066841-6116e61058f4?auto=format&fit=crop&q=80&w=600',
      slotsLeft: 42,
      booked: true,
      province: AdministrativeArea(
        code: '79',
        fullName: 'Thành phố Hồ Chí Minh',
      ),
      hospital: HospitalSummary(
        id: '1',
        name: 'Bệnh viện Chợ Rẫy',
        address: '201B Nguyễn Chí Thanh, TP.HCM',
      ),
      capacity: 160,
      bookedCount: 118,
    ),
    DonationEvent(
      id: 'ev-2',
      title: 'Giọt Hồng Nhân Ái - ĐH Bách Khoa',
      organizer: 'Bệnh viện Truyền máu Huyết học',
      description:
          'Ngày hội tiếp nhận máu tại khuôn viên Bách Khoa, ưu tiên người đã đặt lịch để rút ngắn thời gian chờ.',
      startsAt: DateTime(2026, 7, 7, 8),
      endsAt: DateTime(2026, 7, 7, 16),
      locationName: 'Sân đại sảnh B6, ĐH Bách Khoa TP.HCM, Quận 10',
      location: const GeoPoint(latitude: 10.7721, longitude: 106.6578),
      distanceKm: 4.8,
      urgency: EventUrgency.normal,
      imageUrl:
          'https://images.unsplash.com/photo-1519491050282-cf00c82424b4?auto=format&fit=crop&q=80&w=600',
      slotsLeft: 120,
      province: AdministrativeArea(
        code: '79',
        fullName: 'Thành phố Hồ Chí Minh',
      ),
      hospital: HospitalSummary(
        id: '2',
        name: 'Bệnh viện Truyền máu Huyết học TP.HCM',
      ),
      capacity: 220,
      bookedCount: 100,
    ),
    DonationEvent(
      id: 'ev-3',
      title: 'Hành Trình Đỏ 2026',
      organizer: 'Viện Huyết học - Truyền máu TW',
      description:
          'Chiến dịch cộng đồng kết nối người hiến máu nhắc lại và tình nguyện viên mới đăng ký lần đầu.',
      startsAt: DateTime(2026, 7, 11, 7),
      endsAt: DateTime(2026, 7, 11, 17),
      locationName: 'Số 4 Phạm Ngọc Thạch, Bến Nghé, Quận 1',
      location: const GeoPoint(latitude: 10.7825, longitude: 106.6954),
      distanceKm: 6.5,
      urgency: EventUrgency.high,
      imageUrl:
          'https://images.unsplash.com/photo-1579154204601-01588f351167?auto=format&fit=crop&q=80&w=600',
      slotsLeft: 15,
      province: AdministrativeArea(
        code: '79',
        fullName: 'Thành phố Hồ Chí Minh',
      ),
      capacity: 180,
      bookedCount: 165,
    ),
  ];

  static final bookedAppointments = <DonationAppointment>[
    DonationAppointment(
      id: 'apt-1',
      status: DonationAppointmentStatus.booked,
      bookedAt: DateTime(2026, 7, 1, 9, 30),
      event: donationEvents.first,
    ),
  ];

  static final communityPosts = <CommunityPost>[
    CommunityPost(
      id: 'post-1',
      slug: 'hien-mau-sau-3-thang',
      title: 'Hiến máu sau 3 tháng: vì sao cơ thể cần thời gian hồi phục?',
      excerpt:
          'Khoảng nghỉ 12 tuần giúp cơ thể tái tạo hồng cầu, ổn định thể lực và chuẩn bị tốt cho lần hiến tiếp theo.',
      content:
          'Sau mỗi lần hiến máu, cơ thể cần thời gian để bù lại lượng hồng cầu đã trao đi.\n\nTrong giai đoạn này, bạn nên uống đủ nước, ngủ đủ giấc, bổ sung thực phẩm giàu sắt và theo dõi nhắc lịch trên Pulse Link.',
      imageUrl:
          'https://images.unsplash.com/photo-1530026405186-ed1f139313f8?auto=format&fit=crop&q=80&w=900',
      publishedAt: DateTime(2026, 6, 30, 8),
      audienceLabel: 'Tất cả người dùng',
      viewsCount: 1840,
      sharesCount: 126,
    ),
    CommunityPost(
      id: 'post-2',
      slug: 'tp-hcm-can-them-nguoi-hien-nhom-mau-o',
      title: 'TP.HCM cần thêm người hiến nhóm máu O+ trong tuần này',
      excerpt:
          'Các điểm hiến máu thường quy đang ưu tiên nhóm O+ để bổ sung nguồn dự trữ an toàn.',
      content:
          'Nhóm máu O+ thường được sử dụng trong nhiều tình huống điều trị nên nhu cầu dự trữ luôn cao.\n\nNếu bạn đủ điều kiện sức khỏe, hãy chọn một sự kiện gần mình trong ứng dụng.',
      imageUrl:
          'https://images.unsplash.com/photo-1615461066841-6116e61058f4?auto=format&fit=crop&q=80&w=900',
      publishedAt: DateTime(2026, 7, 1, 7, 30),
      audienceLabel: 'Nhóm máu O+',
      province: AdministrativeArea(
        code: '79',
        fullName: 'Thành phố Hồ Chí Minh',
      ),
      viewsCount: 950,
      sharesCount: 88,
    ),
  ];

  static final donationHistory = <PastDonation>[
    PastDonation(
      id: 'pd-5',
      donatedAt: DateTime(2026, 4, 15),
      locationName: 'Bệnh viện Truyền máu Huyết học TP.HCM',
      volumeMl: 350,
      bloodType: 'O+',
      certificateId: 'PL-2026-9088',
      status: DonationVerificationStatus.verified,
      notes: 'Hemoglobin 14.2 g/dL. Huyết áp tốt.',
    ),
    PastDonation(
      id: 'pd-4',
      donatedAt: DateTime(2026, 1, 10),
      locationName: 'Nhà Văn hóa Thanh Niên Quận 1',
      volumeMl: 350,
      bloodType: 'O+',
      certificateId: 'PL-2026-1120',
      status: DonationVerificationStatus.verified,
      notes: 'Sức khỏe sau hiến tốt.',
    ),
    PastDonation(
      id: 'pd-3',
      donatedAt: DateTime(2025, 10, 5),
      locationName: 'Bệnh viện Chợ Rẫy',
      volumeMl: 450,
      bloodType: 'O+',
      certificateId: 'CR-2025-7764',
      status: DonationVerificationStatus.verified,
      notes: 'Hiến thể tích lớn 450ml thành công.',
    ),
  ];

  static EmergencyAlert emergencyAlert() {
    final now = DateTime.now();

    return EmergencyAlert(
      id: 'sos-${now.millisecondsSinceEpoch}',
      hospitalName: 'Bệnh viện Chợ Rẫy',
      hospitalAddress: '201B Nguyễn Chí Thanh, Quận 5, TP.HCM',
      hospitalProvinceCode: '79',
      hospitalLocation: const GeoPoint(latitude: 10.7565, longitude: 106.6594),
      requiredBloodType: 'O+',
      level: EmergencyLevel.level1,
      unitsNeeded: 6,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 40)),
      message: 'Báo động đỏ thiếu nhóm máu O+ cho ca phẫu thuật cấp cứu.',
    );
  }
}
