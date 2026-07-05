import '../features/community/domain/community_impact.dart';

abstract interface class CommunityImpactService {
  Future<CommunityImpact> getImpact();
}
