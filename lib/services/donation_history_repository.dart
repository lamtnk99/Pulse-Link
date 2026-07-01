import '../features/daily/domain/past_donation.dart';

abstract interface class DonationHistoryRepository {
  Future<List<PastDonation>> getDonationHistory();

  Future<PastDonation> addDonation(PastDonationDraft draft);
}
