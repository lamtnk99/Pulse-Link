import '../../features/community/domain/community_impact.dart';
import '../../services/community_impact_service.dart';
import 'laravel_api_client.dart';

class LaravelCommunityImpactService implements CommunityImpactService {
  const LaravelCommunityImpactService(this._client);

  final LaravelApiClient _client;

  @override
  Future<CommunityImpact> getImpact() async {
    final json = await _client.getJson('/api/mobile/community-impact');
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return CommunityImpact.fromJson(data);
    }
    return CommunityImpact.fromJson(json);
  }
}
