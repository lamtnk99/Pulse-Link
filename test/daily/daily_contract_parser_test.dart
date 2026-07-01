import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_link/features/community/domain/community_post.dart';
import 'package:pulse_link/features/daily/domain/donation_appointment.dart';
import 'package:pulse_link/features/daily/domain/donation_event.dart';

void main() {
  test('DonationEvent parses Laravel detail contract', () {
    final event = DonationEvent.fromJson({
      'id': '1',
      'title': 'Chủ Nhật Đỏ - Đại học Bách Khoa TP.HCM',
      'organizer': 'Hội Chữ thập đỏ TP.HCM',
      'description': 'Mô tả sự kiện',
      'starts_at': '2026-07-06T07:30:00+07:00',
      'ends_at': '2026-07-06T11:30:00+07:00',
      'location_name': 'Sân đại sảnh B6',
      'location': {'latitude': 10.7721, 'longitude': 106.6578},
      'distance_km': 1.6,
      'urgency': 'high',
      'image_url': null,
      'slots_left': 218,
      'booked': true,
      'appointment_status': 'booked',
      'capacity': 220,
      'booked_count': 2,
      'province': {
        'code': '79',
        'full_name': 'Thành phố Hồ Chí Minh',
      },
      'hospital': {
        'id': 1,
        'name': 'Bệnh viện Chợ Rẫy',
        'address': '201B Nguyễn Chí Thanh',
      },
    });

    expect(event.booked, isTrue);
    expect(event.appointmentStatus, 'booked');
    expect(event.province?.fullName, 'Thành phố Hồ Chí Minh');
    expect(event.hospital?.name, 'Bệnh viện Chợ Rẫy');
  });

  test('DonationAppointment parses booked event payload', () {
    final appointment = DonationAppointment.fromJson({
      'id': '10',
      'status': 'booked',
      'booked_at': '2026-07-01T09:30:00+07:00',
      'event': {
        'id': '1',
        'title': 'Ngày hội hiến máu',
        'organizer': 'Bệnh viện Chợ Rẫy',
        'starts_at': '2026-07-06T07:30:00+07:00',
        'ends_at': '2026-07-06T11:30:00+07:00',
        'location_name': 'TP.HCM',
        'location': {'latitude': 10.7721, 'longitude': 106.6578},
        'distance_km': 1.6,
        'urgency': 'normal',
        'image_url': null,
        'slots_left': 12,
        'booked': true,
      },
    });

    expect(appointment.status, DonationAppointmentStatus.booked);
    expect(appointment.event.booked, isTrue);
  });

  test('CommunityPost parses published post payload', () {
    final post = CommunityPost.fromJson({
      'id': '1',
      'slug': 'hien-mau-sau-3-thang',
      'title': 'Hiến máu sau 3 tháng',
      'excerpt': 'Tóm tắt',
      'content': 'Nội dung',
      'image_url': null,
      'published_at': '2026-07-01T08:00:00+07:00',
      'audience_label': 'Tất cả người dùng',
      'views_count': 12,
      'shares_count': 3,
      'province': {'code': '79', 'full_name': 'Thành phố Hồ Chí Minh'},
    });

    expect(post.slug, 'hien-mau-sau-3-thang');
    expect(post.province?.code, '79');
    expect(post.viewsCount, 12);
  });
}
