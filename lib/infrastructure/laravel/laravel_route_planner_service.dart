import '../../core/location/geo_point.dart';
import '../../features/emergency/domain/route_plan.dart';
import '../../services/route_planner_service.dart';
import 'laravel_api_client.dart';

class LaravelRoutePlannerService implements RoutePlannerService {
  const LaravelRoutePlannerService(this._client);

  final LaravelApiClient _client;

  @override
  Future<RoutePlan> planRoute({
    required GeoPoint origin,
    required GeoPoint destination,
    double? preferredDistanceKm,
  }) async {
    final json = await _client.postJson(
      '/api/mobile/routes/plan',
      body: {
        'origin': origin.toJson(),
        'destination': destination.toJson(),
        'preferred_distance_km': preferredDistanceKm,
      },
    );
    final data = json['data'];
    return RoutePlan.fromJson(
      data is Map<String, dynamic> ? data : json,
    );
  }
}
