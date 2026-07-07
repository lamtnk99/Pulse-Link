class DonationCampaign {
  const DonationCampaign({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.targetAmount,
    required this.currentAmount,
    this.pointValueVnd = 250,
    required this.status,
    this.beneficiaryName,
    this.beneficiaryStory,
    this.impactUnit,
    this.impactPerUnitAmount,
    this.urgencyLevel,
    this.donorCount = 0,
    this.expiresAt,
    this.createdAt,
  });

  factory DonationCampaign.fromJson(Map<String, dynamic> json) {
    return DonationCampaign(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Dự án quyên góp',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
      pointValueVnd: (json['point_value_vnd'] as num?)?.toInt() ?? 250,
      status: json['status'] as String? ?? 'active',
      beneficiaryName: json['beneficiary_name'] as String?,
      beneficiaryStory: json['beneficiary_story'] as String?,
      impactUnit: json['impact_unit'] as String?,
      impactPerUnitAmount: (json['impact_per_unit_amount'] as num?)?.toDouble(),
      urgencyLevel: json['urgency_level'] as String?,
      donorCount: (json['donor_count'] as num?)?.toInt() ?? 0,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  final String id;
  final String title;
  final String description;
  final String? imageUrl;

  /// Mục tiêu và số tiền đã quyên góp (VND). Mọi khoản góp — tiền mặt lẫn điểm
  /// Hero — đều gộp về trục tiền duy nhất này.
  final double targetAmount;
  final double currentAmount;

  /// Tỉ giá quy đổi điểm Hero sang VND (mặc định 1 điểm = 250đ, lấy từ backend).
  final int pointValueVnd;

  final String status;

  /// Người/cộng đồng thụ hưởng — để người quyên góp hình dung mình đang giúp ai.
  final String? beneficiaryName;

  /// Câu chuyện hoàn cảnh, chất liệu thấu cảm chính của màn chi tiết.
  final String? beneficiaryStory;

  /// Đơn vị tác động cụ thể, ví dụ "phần cơm", "đơn vị máu".
  final String? impactUnit;

  /// Số VND để tạo ra một [impactUnit].
  final double? impactPerUnitAmount;

  /// null | 'normal' | 'urgent' | 'critical'.
  final String? urgencyLevel;

  /// Tổng số người đã đóng góp thành công (hiệu ứng cộng đồng).
  final int donorCount;

  final DateTime? expiresAt;
  final DateTime? createdAt;

  /// Tiến độ quỹ (0..1) theo mục tiêu tiền.
  double get progress {
    if (targetAmount <= 0) return 0.0;
    final p = currentAmount / targetAmount;
    return p > 1.0 ? 1.0 : p;
  }

  bool get hasStory => (beneficiaryStory ?? '').trim().isNotEmpty;
  bool get hasImpactUnit => (impactUnit ?? '').trim().isNotEmpty;

  /// Số ngày còn lại tới hạn, null nếu không đặt hạn.
  int? get daysLeft {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now()).inHours;
    if (diff <= 0) return 0;
    return (diff / 24).ceil();
  }

  /// Quy đổi số điểm Hero sang VND theo tỉ giá của chiến dịch.
  double amountFromPoints(int points) => points * pointValueVnd.toDouble();

  /// Quy đổi một số tiền sang số đơn vị tác động (làm tròn xuống).
  int impactUnitsForAmount(double amount) {
    if (impactPerUnitAmount == null || impactPerUnitAmount! <= 0) return 0;
    return (amount / impactPerUnitAmount!).floor();
  }

  /// Quy đổi một số điểm sang số đơn vị tác động — điểm được quy ra VND trước.
  int impactUnitsForPoints(int points) => impactUnitsForAmount(amountFromPoints(points));
}
