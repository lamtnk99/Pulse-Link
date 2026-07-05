import '../features/donation/domain/donation_campaign.dart';

abstract interface class DonationFundService {
  Future<List<DonationCampaign>> getCampaigns();
  
  Future<Map<String, dynamic>> getCampaignDetail(String campaignId);
  
  Future<Map<String, dynamic>> donateCash({
    required String campaignId,
    required double amount,
    required String paymentMethod,
    String? donorName,
    String? message,
    bool isAnonymous = false,
  });
  
  Future<Map<String, dynamic>> donatePoints({
    required String campaignId,
    required int points,
    String? donorName,
    String? message,
    bool isAnonymous = false,
  });

  Future<String> checkTransactionStatus(String transactionId);
}
