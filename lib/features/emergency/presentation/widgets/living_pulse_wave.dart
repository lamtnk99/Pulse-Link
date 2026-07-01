import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/pulse_link_theme.dart';

class LivingPulseWave extends StatelessWidget {
  const LivingPulseWave({
    super.key,
    required this.progress,
    required this.intensity,
  });

  final double progress;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      width: double.infinity,
      child: CustomPaint(
        painter: _PulseWavePainter(
          progress: progress,
          intensity: intensity,
        ),
      ),
    );
  }
}

class _PulseWavePainter extends CustomPainter {
  const _PulseWavePainter({
    required this.progress,
    required this.intensity,
  });

  final double progress;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final normalizedIntensity = intensity.clamp(0.0, 1.0).toDouble();
    final centerY = size.height / 2;
    final amplitude = 18 + normalizedIntensity * 36;
    final phase = progress * 2 * math.pi * (1 + normalizedIntensity * 1.8);

    final path = Path();
    for (var x = 0.0; x <= size.width; x += 1) {
      final t = x / size.width;
      final carrier = math.sin(t * math.pi * 7 + phase) * amplitude * 0.22;
      final spikePosition = (progress + normalizedIntensity * 0.14) % 1;
      var distance = (t - spikePosition).abs();
      if (distance > 0.5) distance = 1 - distance;
      final spike =
          math.exp(-math.pow(distance * 22, 2)) * amplitude * -1.2;
      final rebound =
          math.exp(-math.pow((distance - 0.055) * 20, 2)) * amplitude * 0.72;
      final y = centerY + carrier + spike + rebound;

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glow = Paint()
      ..color = PulseLinkTheme.alertRed.withOpacity(0.16 + intensity * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final stroke = Paint()
      ..color = PulseLinkTheme.alertRed.withOpacity(0.72 + intensity * 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 + intensity * 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);

    final activeX = size.width * progress;
    canvas.drawCircle(
      Offset(activeX, centerY),
      8 + intensity * 8,
      Paint()..color = PulseLinkTheme.alertRed.withOpacity(0.16),
    );
    canvas.drawCircle(
      Offset(activeX, centerY),
      3.5 + intensity * 2,
      Paint()..color = PulseLinkTheme.alertRed,
    );
  }

  @override
  bool shouldRepaint(covariant _PulseWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity;
  }
}
