class VietnameseLabels {
  const VietnameseLabels._();

  static String text(String value) {
    return _textMap[value] ?? value;
  }

  static String heroLevel(String value) {
    return switch (value) {
      'Bronze Badge' => 'Huy hiệu Đồng',
      'Silver Badge' => 'Huy hiệu Bạc',
      'Gold Badge' => 'Huy hiệu Vàng',
      'Platinum Badge' => 'Huy hiệu Bạch kim',
      _ => value,
    };
  }

  static String badgeTitle(String value) {
    return switch (value) {
      'Hiep Si Dong' => 'Hiệp sĩ Đồng',
      'Hiep Si Bac' => 'Hiệp sĩ Bạc',
      'Hiep Si Vang' => 'Hiệp sĩ Vàng',
      'Hiep Si Bach Kim' => 'Hiệp sĩ Bạch kim',
      _ => text(value),
    };
  }

  static String verificationStatus(String value) {
    return switch (value) {
      'verified' => 'Đã xác minh',
      'pending' => 'Chờ xác minh',
      _ => text(value),
    };
  }

  static const Map<String, String> _textMap = {
    'Benh vien Cho Ray': 'Bệnh viện Chợ Rẫy',
    'Benh vien Truyen mau Huyet hoc TP.HCM':
        'Bệnh viện Truyền máu Huyết học TP.HCM',
    'Benh vien Bach Mai': 'Bệnh viện Bạch Mai',
    'Benh vien Trung uong Hue': 'Bệnh viện Trung ương Huế',
    'Benh vien Da Nang': 'Bệnh viện Đà Nẵng',
    'Benh vien Da khoa Trung uong Can Tho':
        'Bệnh viện Đa khoa Trung ương Cần Thơ',
    'Chu Nhat Do - Dai hoc Bach Khoa TP.HCM':
        'Chủ Nhật Đỏ - Đại học Bách Khoa TP.HCM',
    'Chu Nhat Do - FPT Polytechnic': 'Chủ Nhật Đỏ - FPT Polytechnic',
    'Giot Hong Nhan Ai - Cong vien phan mem Quang Trung':
        'Giọt Hồng Nhân Ái - Công viên Phần mềm Quang Trung',
    'Giot Hong Nhan Ai - DH Bach Khoa': 'Giọt Hồng Nhân Ái - ĐH Bách Khoa',
    'Ngay Hoi Hien Mau - Bach Mai': 'Ngày Hội Hiến Máu - Bạch Mai',
    'Trao Giot Mau Dao - Da Nang': 'Trao Giọt Máu Đào - Đà Nẵng',
    'Sac Do Tay Do - Can Tho': 'Sắc Đỏ Tây Đô - Cần Thơ',
    'Hanh Trinh Do 2026': 'Hành Trình Đỏ 2026',
    'Hoi Chu Thap Do TP.HCM': 'Hội Chữ thập đỏ TP.HCM',
    'Trung tam Hien mau Nhan dao TP.HCM':
        'Trung tâm Hiến máu Nhân đạo TP.HCM',
    'Vien Huyet hoc Truyen mau Trung uong':
        'Viện Huyết học Truyền máu Trung ương',
    'Thanh doan Da Nang': 'Thành đoàn Đà Nẵng',
    'Hoi Chu Thap Do Can Tho': 'Hội Chữ thập đỏ Cần Thơ',
    'Cong vien phan mem Quang Trung, TP.HCM':
        'Công viên Phần mềm Quang Trung, TP.HCM',
    'Cong vien phan mem Quang Trung, Quan 12':
        'Công viên Phần mềm Quang Trung, Quận 12',
    'San dai sanh B6, Dai hoc Bach Khoa TP.HCM':
        'Sảnh đại sảnh B6, Đại học Bách Khoa TP.HCM',
    'San dai sanh B6, DH Bach Khoa TP.HCM, Quan 10':
        'Sảnh đại sảnh B6, ĐH Bách Khoa TP.HCM, Quận 10',
    '78 Giai Phong, Ha Noi': '78 Giải Phóng, Hà Nội',
    '124 Hai Phong, Da Nang': '124 Hải Phòng, Đà Nẵng',
    '315 Nguyen Van Linh, Can Tho': '315 Nguyễn Văn Linh, Cần Thơ',
    '201B Nguyen Chi Thanh, Quan 5, TP.HCM':
        '201B Nguyễn Chí Thanh, Quận 5, TP.HCM',
    'Nha Van Hoa Thanh Nien Quan 1': 'Nhà Văn hóa Thanh niên Quận 1',
    'Hemoglobin 14.2 g/dL. Huyet ap tot.':
        'Hemoglobin 14.2 g/dL. Huyết áp tốt.',
    'Suc khoe sau hien tot.': 'Sức khỏe sau hiến tốt.',
    'Hien the tich lon 450ml thanh cong.':
        'Hiến thể tích lớn 450ml thành công.',
    'Bao dong do thieu nhom mau O+ cho ca phau thuat cap cuu.':
        'Báo động đỏ thiếu nhóm máu O+ cho ca phẫu thuật cấp cứu.',
  };
}
