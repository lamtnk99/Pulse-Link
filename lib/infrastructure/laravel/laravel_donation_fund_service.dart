import '../../features/donation/domain/donation_campaign.dart';
import '../../features/donation/domain/campaign_donation.dart';
import '../../services/donation_fund_service.dart';
import 'laravel_api_client.dart';

class LaravelDonationFundService implements DonationFundService {
  const LaravelDonationFundService(this._client);

  final LaravelApiClient _client;

  @override
  Future<List<DonationCampaign>> getCampaigns() async {
    final list = await _client.getList('/api/mobile/donation/campaigns');
    return list
        .cast<Map<String, dynamic>>()
        .map(DonationCampaign.fromJson)
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> getCampaignDetail(String campaignId) async {
    final json = await _client.getJson('/api/mobile/donation/campaigns/$campaignId');
    final data = _unwrapData(json);
    
    final campaignJson = data['campaign'] as Map<String, dynamic>;
    final leaderboardJson = data['leaderboard'] as List<dynamic>? ?? const [];
    
    return {
      'campaign': DonationCampaign.fromJson(campaignJson),
      'leaderboard': leaderboardJson
          .cast<Map<String, dynamic>>()
          .map(CampaignDonation.fromJson)
          .toList(growable: false),
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
    final json = await _client.postJson(
      '/api/mobile/donation/campaigns/$campaignId/donate-cash',
      body: {
        'amount': amount,
        'payment_method': paymentMethod,
        if (donorName != null && donorName.isNotEmpty) 'donor_name': donorName,
        if (message != null && message.isNotEmpty) 'message': message,
        'is_anonymous': isAnonymous,
      },
    );
    return _unwrapData(json);
  }

  @override
  Future<Map<String, dynamic>> donatePoints({
    required String campaignId,
    required int points,
    String? donorName,
    String? message,
    bool isAnonymous = false,
  }) async {
    final json = await _client.postJson(
      '/api/mobile/donation/campaigns/$campaignId/donate-points',
      body: {
        'points': points,
        if (donorName != null && donorName.isNotEmpty) 'donor_name': donorName,
        if (message != null && message.isNotEmpty) 'message': message,
        'is_anonymous': isAnonymous,
      },
    );
    return _unwrapData(json);
  }

  @override
  Future<String> checkTransactionStatus(String transactionId) async {
    final json = await _client.getJson('/api/mobile/donation/transactions/$transactionId/status');
    final data = _unwrapData(json);
    return data['status'] as String;
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }
}
