import 'package:flutter/material.dart';

import '../../../../core/theme/pulse_link_theme.dart';
import '../../domain/donation_event.dart';

class EventMapPreview extends StatelessWidget {
  const EventMapPreview({
    super.key,
    required this.events,
  });

  final List<DonationEvent> events;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.55,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _EventMapPainter(events.length),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: _MapHud(count: events.length),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapHud extends StatelessWidget {
  const _MapHud({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.56),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$count điểm hiến máu gần bạn',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventMapPainter extends CustomPainter {
  const _EventMapPainter(this.count);

  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final road = Path()
      ..moveTo(size.width * 0.08, size.height * 0.78)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.62,
        size.width * 0.36,
        size.height * 0.18,
        size.width * 0.62,
        size.height * 0.32,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.43,
        size.width * 0.72,
        size.height * 0.7,
        size.width * 0.93,
        size.height * 0.82,
      );
    canvas.drawPath(road, roadPaint);

    final points = [
      Offset(size.width * 0.24, size.height * 0.62),
      Offset(size.width * 0.54, size.height * 0.36),
      Offset(size.width * 0.78, size.height * 0.58),
    ];
    final eventPaint = Paint()..color = PulseLinkTheme.primaryRed;
    final ringPaint = Paint()
      ..color = PulseLinkTheme.primaryRed.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < count && i < points.length; i++) {
      canvas.drawCircle(points[i], 16, ringPaint);
      canvas.drawCircle(points[i], 6, eventPaint);
    }

    final user = Offset(size.width * 0.14, size.height * 0.76);
    canvas.drawCircle(
      user,
      10,
      Paint()..color = PulseLinkTheme.successGreen.withOpacity(0.2),
    );
    canvas.drawCircle(user, 4, Paint()..color = PulseLinkTheme.successGreen);
  }

  @override
  bool shouldRepaint(covariant _EventMapPainter oldDelegate) {
    return oldDelegate.count != count;
  }
}
