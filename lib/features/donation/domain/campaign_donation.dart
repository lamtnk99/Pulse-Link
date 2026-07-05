class CampaignDonation {
  const CampaignDonation({
    required this.donorName,
    required this.amount,
    required this.points,
    this.message,
    this.isAnonymous = false,
    this.lastDonatedAt,
  });

  factory CampaignDonation.fromJson(Map<String, dynamic> json) {
    return CampaignDonation(
      donorName: json['donor_name'] as String? ?? 'Hiệp sĩ ẩn danh',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      message: (json['message'] as String?)?.trim().isNotEmpty == true
          ? (json['message'] as String).trim()
          : null,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      lastDonatedAt: json['last_donated_at'] != null
          ? DateTime.tryParse(json['last_donated_at'] as String)
          : null,
    );
  }

  final String donorName;
  final double amount;
  final int points;

  /// Lời chúc gửi tới chiến dịch — chất liệu thấu cảm hiển thị trên bảng vàng.
  final String? message;
  final bool isAnonymous;
  final DateTime? lastDonatedAt;

  bool get hasMessage => (message ?? '').trim().isNotEmpty;

  /// Chữ cái đầu của tên cuối (tên gọi) để tạo avatar khi không có ảnh.
  /// Ẩn danh dùng ký hiệu trái tim.
  String get initial {
    if (isAnonymous) return '♥';
    final trimmed = donorName.trim();
    if (trimmed.isEmpty) return '♥';
    final lastWord = trimmed.split(RegExp(r'\s+')).last;
    return lastWord.substring(0, 1).toUpperCase();
  }
}
