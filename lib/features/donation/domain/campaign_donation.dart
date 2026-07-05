class CampaignDonation {
  const CampaignDonation({
    required this.donorName,
    required this.amount,
    required this.points,
    this.lastDonatedAt,
  });

  factory CampaignDonation.fromJson(Map<String, dynamic> json) {
    return CampaignDonation(
      donorName: json['donor_name'] as String? ?? 'Hiệp sĩ ẩn danh',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      lastDonatedAt: json['last_donated_at'] != null 
          ? DateTime.tryParse(json['last_donated_at'] as String) 
          : null,
    );
  }

  final String donorName;
  final double amount;
  final int points;
  final DateTime? lastDonatedAt;
}
