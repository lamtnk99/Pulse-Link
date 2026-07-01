import '../core/location/geo_point.dart';
import '../features/emergency/domain/route_plan.dart';

abstract interface class RoutePlannerService {
  Future<RoutePlan> planRoute({
    required GeoPoint origin,
    required GeoPoint destination,
    double? preferredDistanceKm,
  });
}
