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

  bool get isFinancial => type == 'financial' || type == 'both';
  bool get isPoints => type == 'points' || type == 'both';
}
