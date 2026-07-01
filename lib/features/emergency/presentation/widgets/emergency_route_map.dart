import 'package:flutter/material.dart';

import '../../../../core/theme/pulse_link_theme.dart';
import '../../../../core/utils/vietnamese_labels.dart';
import '../../domain/route_plan.dart';

class EmergencyRouteMap extends StatelessWidget {
  const EmergencyRouteMap({
    super.key,
    required this.routePlan,
    required this.hospitalName,
    required this.intensity,
  });

  final RoutePlan routePlan;
  final String hospitalName;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.35,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1117),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _EmergencyRoutePainter(
                  intensity: intensity,
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _RouteHud(
                hospitalName: hospitalName,
                distanceKm: routePlan.distanceKm,
                estimatedMinutes: routePlan.estimatedMinutes,
              ),
            ),
            const Positioned(
              left: 24,
              bottom: 22,
              child: _MapLabel(
                icon: Icons.person_pin_circle,
                label: 'Bạn',
                color: PulseLinkTheme.successGreen,
              ),
            ),
            Positioned(
              right: 22,
              top: 86,
              child: _MapLabel(
                icon: Icons.local_hospital,
                label: VietnameseLabels.text(hospitalName),
                color: PulseLinkTheme.alertRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteHud extends StatelessWidget {
  const _RouteHud({
    required this.hospitalName,
    required this.distanceKm,
    required this.estimatedMinutes,
  });

  final String hospitalName;
  final double distanceKm;
  final int estimatedMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, color: PulseLinkTheme.successGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  VietnameseLabels.text(hospitalName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${distanceKm.toStringAsFixed(1)} km · $estimatedMinutes phút · tuyến ưu tiên',
                  style: const TextStyle(
                    color: PulseLinkTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLabel extends StatelessWidget {
  const _MapLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.64),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyRoutePainter extends CustomPainter {
  const _EmergencyRoutePainter({
    required this.intensity,
  });

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);
    _paintRoads(canvas, size);
    _paintRoute(canvas, size);
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintRoads(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (final offset in [0.2, 0.45, 0.72]) {
      canvas.drawLine(
        Offset(size.width * offset, 0),
        Offset(size.width * (offset - 0.18), size.height),
        paint,
      );
    }

    for (final offset in [0.3, 0.58, 0.84]) {
      canvas.drawLine(
        Offset(0, size.height * offset),
        Offset(size.width, size.height * (offset - 0.12)),
        paint,
      );
    }
  }

  void _paintRoute(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.78)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.62,
        size.width * 0.45,
        size.height * 0.7,
        size.width * 0.54,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.3,
        size.width * 0.78,
        size.height * 0.32,
        size.width * 0.86,
        size.height * 0.22,
      );

    final glow = Paint()
      ..color = PulseLinkTheme.successGreen.withOpacity(0.18 + intensity * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 + intensity * 6
      ..strokeCap = StrokeCap.round;
    final routePaint = Paint()
      ..color = PulseLinkTheme.successGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, routePaint);

    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.78),
      7,
      Paint()..color = PulseLinkTheme.successGreen,
    );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.22),
      8,
      Paint()..color = PulseLinkTheme.alertRed,
    );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.22),
      16 + intensity * 12,
      Paint()..color = PulseLinkTheme.alertRed.withOpacity(0.12),
    );
  }

  @override
  bool shouldRepaint(covariant _EmergencyRoutePainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}
