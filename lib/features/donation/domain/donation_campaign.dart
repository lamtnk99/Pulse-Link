class DonationCampaign {
  const DonationCampaign({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.type,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetPoints,
    required this.currentPoints,
    required this.status,
    this.beneficiaryName,
    this.beneficiaryStory,
    this.impactUnit,
    this.impactPerUnitAmount,
    this.impactPerUnitPoints,
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
      type: json['type'] as String? ?? 'both',
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
      targetPoints: (json['target_points'] as num?)?.toInt() ?? 0,
      currentPoints: (json['current_points'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
      beneficiaryName: json['beneficiary_name'] as String?,
      beneficiaryStory: json['beneficiary_story'] as String?,
      impactUnit: json['impact_unit'] as String?,
      impactPerUnitAmount: (json['impact_per_unit_amount'] as num?)?.toDouble(),
      impactPerUnitPoints: (json['impact_per_unit_points'] as num?)?.toInt(),
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
  final String type;
  final double targetAmount;
  final double currentAmount;
  final int targetPoints;
  final int currentPoints;
  final String status;

  /// Người/cộng đồng thụ hưởng — để người quyên góp hình dung mình đang giúp ai.
  final String? beneficiaryName;

  /// Câu chuyện hoàn cảnh, chất liệu thấu cảm chính của màn chi tiết.
  final String? beneficiaryStory;

  /// Đơn vị tác động cụ thể, ví dụ "phần cơm", "đơn vị máu".
  final String? impactUnit;

  /// Số VND để tạo ra một [impactUnit] (campaign tài chính).
  final double? impactPerUnitAmount;

  /// Số điểm Hero để tạo ra một [impactUnit] (campaign điểm).
  final int? impactPerUnitPoints;

  /// null | 'normal' | 'urgent' | 'critical'.
  final String? urgencyLevel;

  /// Tổng số người đã đóng góp thành công (hiệu ứng cộng đồng).
  final int donorCount;

  final DateTime? expiresAt;
  final DateTime? createdAt;

  double get financialProgress {
    if (targetAmount <= 0) return 0.0;
    final progress = currentAmount / targetAmount;
    return progress > 1.0 ? 1.0 : progress;
  }

  double get pointsProgress {
    if (targetPoints <= 0) return 0.0;
    final progress = currentPoints / targetPoints;
    return progress > 1.0 ? 1.0 : progress;
  }

  /// Chiến dịch có đặt mục tiêu tài chính không (để hiện thanh tiến độ tiền).
  bool get hasFinancialGoal => targetAmount > 0;

  /// Chiến dịch có đặt mục tiêu điểm không (để hiện thanh tiến độ điểm).
  bool get hasPointsGoal => targetPoints > 0;

  // Mọi chiến dịch đều NHẬN cả tiền mặt lẫn điểm Hero. Các getter dưới đây chỉ
  // quyết định việc HIỂN THỊ thanh tiến độ theo mục tiêu đã đặt, không giới hạn
  // hình thức quyên góp.
  bool get isFinancial => hasFinancialGoal;
  bool get isPoints => hasPointsGoal;

  bool get hasStory => (beneficiaryStory ?? '').trim().isNotEmpty;
  bool get hasImpactUnit => (impactUnit ?? '').trim().isNotEmpty;

  /// Số ngày còn lại tới hạn, null nếu không đặt hạn.
  int? get daysLeft {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now()).inHours;
    if (diff <= 0) return 0;
    return (diff / 24).ceil();
  }

  /// Quy đổi một số tiền sang số đơn vị tác động (làm tròn xuống).
  int impactUnitsForAmount(double amount) {
    if (impactPerUnitAmount == null || impactPerUnitAmount! <= 0) return 0;
    return (amount / impactPerUnitAmount!).floor();
  }

  /// Quy đổi một số điểm sang số đơn vị tác động (làm tròn xuống).
  int impactUnitsForPoints(int points) {
    if (impactPerUnitPoints == null || impactPerUnitPoints! <= 0) return 0;
    return (points / impactPerUnitPoints!).floor();
  }
}
