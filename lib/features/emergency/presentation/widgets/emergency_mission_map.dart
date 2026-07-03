import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/location/geo_point.dart';
import '../../../../core/theme/pulse_link_theme.dart';
import '../../../../core/utils/vietnamese_labels.dart';
import '../../domain/emergency_alert.dart';
import '../../domain/route_plan.dart';

class EmergencyMissionMap extends StatelessWidget {
  const EmergencyMissionMap({
    super.key,
    required this.alert,
    required this.routePlan,
    required this.userLocation,
    required this.pulse,
  });

  final EmergencyAlert alert;
  final RoutePlan routePlan;
  final GeoPoint? userLocation;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final routePoints = routePlan.polyline
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    final hospitalPoint = LatLng(
      alert.hospitalLocation.latitude,
      alert.hospitalLocation.longitude,
    );
    final userPoint = userLocation == null
        ? null
        : LatLng(userLocation!.latitude, userLocation!.longitude);
    final camera = _MissionCamera.fromPoints([
      if (userPoint != null) userPoint,
      hospitalPoint,
      ...routePoints,
    ]);
    final beat = 0.5 + 0.5 * math.sin(pulse * math.pi * 2);

    return AspectRatio(
      aspectRatio: 1.02,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: camera.center,
                  initialZoom: camera.zoom,
                  maxZoom: 18,
                  minZoom: 5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.flingAnimation |
                        InteractiveFlag.pinchMove |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.pulselink.app',
                    tileProvider: CancellableNetworkTileProvider(),
                  ),
                  if (routePoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          color: PulseLinkTheme.alertRed.withOpacity(
                            0.78 + beat * 0.22,
                          ),
                          strokeWidth: 4.5 + beat * 1.5,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (userPoint != null)
                        Marker(
                          point: userPoint,
                          width: 54,
                          height: 54,
                          child: _MissionMarker(
                            icon: Icons.person_pin_circle,
                            color: PulseLinkTheme.successGreen,
                            label: 'Bạn',
                            pulse: pulse,
                          ),
                        ),
                      Marker(
                        point: hospitalPoint,
                        width: 78,
                        height: 78,
                        child: _MissionMarker(
                          icon: Icons.local_hospital,
                          color: PulseLinkTheme.alertRed,
                          label: VietnameseLabels.text(alert.hospitalName),
                          pulse: pulse,
                          urgent: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              right: 14,
              child: _MissionMapHud(
                distanceKm: routePlan.distanceKm,
                estimatedMinutes: routePlan.estimatedMinutes,
                hasUserLocation: userLocation != null,
              ),
            ),
            const Positioned(
              left: 14,
              bottom: 12,
              child: _AttributionBadge(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionMapHud extends StatelessWidget {
  const _MissionMapHud({
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.hasUserLocation,
  });

  final double distanceKm;
  final int estimatedMinutes;
  final bool hasUserLocation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.route, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasUserLocation
                    ? '${distanceKm.toStringAsFixed(1)} km · khoảng $estimatedMinutes phút'
                    : 'Chưa có vị trí hiện tại · mở chỉ đường bằng Google Maps',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionMarker extends StatelessWidget {
  const _MissionMarker({
    required this.icon,
    required this.color,
    required this.label,
    required this.pulse,
    this.urgent = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final double pulse;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final beat = 0.5 + 0.5 * math.sin(pulse * math.pi * 2);
    final coreSize = urgent ? 50.0 + beat * 5 : 44.0 + beat * 2;

    return Tooltip(
      message: label,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (urgent)
            Container(
              width: 60 + beat * 18,
              height: 60 + beat * 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.08 + beat * 0.12),
                border: Border.all(
                  color: color.withOpacity(0.24 + beat * 0.28),
                ),
              ),
            ),
          Container(
            width: coreSize,
            height: coreSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.28 + beat * 0.22),
                  blurRadius: 16 + beat * 14,
                  spreadRadius: 2 + beat * 3,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: urgent ? 34 : 30),
          ),
        ],
      ),
    );
  }
}

class _AttributionBadge extends StatelessWidget {
  const _AttributionBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          'OpenStreetMap',
          style: TextStyle(
            color: Color(0xFF475467),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MissionCamera {
  const _MissionCamera({
    required this.center,
    required this.zoom,
  });

  final LatLng center;
  final double zoom;

  factory _MissionCamera.fromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      return const _MissionCamera(
        center: LatLng(16.0471, 108.2068),
        zoom: 6,
      );
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();
    final span = math.max(latSpan, lngSpan);
    final zoom = span < 0.01
        ? 14.5
        : span < 0.04
            ? 13.0
            : span < 0.1
                ? 11.5
                : span < 0.4
                    ? 9.5
                    : 7.5;

    return _MissionCamera(
      center: LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
      zoom: zoom,
    );
  }
}
