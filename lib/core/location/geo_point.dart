import 'dart:math' as math;

class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
  });

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  double distanceKmTo(GeoPoint other) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(other.latitude - latitude);
    final dLon = _degreesToRadians(other.longitude - longitude);
    final lat1 = _degreesToRadians(latitude);
    final lat2 = _degreesToRadians(other.latitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}
