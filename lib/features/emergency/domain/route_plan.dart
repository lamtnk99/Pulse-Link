import '../../../core/location/geo_point.dart';

class RoutePlan {
  const RoutePlan({
    required this.polyline,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.summary,
  });

  factory RoutePlan.fromJson(Map<String, dynamic> json) {
    final rawPolyline = json['polyline'] as List<dynamic>;
    return RoutePlan(
      polyline: rawPolyline
          .cast<Map<String, dynamic>>()
          .map(GeoPoint.fromJson)
          .toList(growable: false),
      distanceKm: (json['distance_km'] as num).toDouble(),
      estimatedMinutes: json['estimated_minutes'] as int,
      summary: json['summary'] as String,
    );
  }

  final List<GeoPoint> polyline;
  final double distanceKm;
  final int estimatedMinutes;
  final String summary;
}
