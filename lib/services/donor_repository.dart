import '../core/location/geo_point.dart';
import '../features/profile/domain/donor_profile.dart';

abstract interface class DonorRepository {
  Future<DonorProfile> getCurrentProfile();

  Future<void> saveProfile(DonorProfile profile);

  Future<void> updateBaseLocation(GeoPoint location);

  /// Cập nhật một phần thông tin hồ sơ (chỉ gửi các field cần đổi) và trả về hồ sơ mới.
  Future<DonorProfile> updateProfile(Map<String, dynamic> fields);

  /// Tải ảnh (CCCD) lên, trả về URL công khai.
  Future<String> uploadIdImage(String filePath);
}
