import '../core/location/geo_point.dart';

abstract interface class LocationService {
  Future<GeoPoint> getCurrentLocation();
}
