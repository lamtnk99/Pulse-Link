import '../features/profile/domain/donor_profile.dart';

abstract interface class DonorRepository {
  Future<DonorProfile> getCurrentProfile();

  Future<void> saveProfile(DonorProfile profile);
}
