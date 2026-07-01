import 'package:flutter/material.dart';

import '../../../../core/theme/pulse_link_theme.dart';
import '../../domain/dispatch_wave.dart';
import '../../domain/emergency_alert.dart';

class DispatchWavePanel extends StatelessWidget {
  const DispatchWavePanel({
    super.key,
    required this.alert,
    required this.dispatchMatch,
    required this.animationValue,
  });

  final EmergencyAlert alert;
  final DispatchMatch dispatchMatch;
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PulseLinkTheme.alertRed.withOpacity(0.24)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: CustomPaint(
              painter: _DispatchRingsPainter(
                value: animationValue,
                wave: dispatchMatch.wave,
              ),
              child: const Center(
                child: Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dispatchMatch.wave.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.level.dispatchDescription,
                  style: const TextStyle(
                    color: PulseLinkTheme.mutedText,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cách bệnh viện ${dispatchMatch.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: PulseLinkTheme.alertRed,
                    fontWeight: FontWeight.w800,
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

class _DispatchRingsPainter extends CustomPainter {
  const _DispatchRingsPainter({
    required this.value,
    required this.wave,
  });

  final double value;
  final DispatchWave wave;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final waveBoost = switch (wave) {
      DispatchWave.local5km => 0.6,
      DispatchWave.province30km => 0.8,
      DispatchWave.interProvince => 1.0,
      DispatchWave.outOfRange => 0.25,
    };

    for (var index = 0; index < 3; index++) {
      final shifted = (value + index / 3) % 1;
      final radius = 13 + shifted * 30 * waveBoost;
      final opacity = (1 - shifted).clamp(0.0, 1.0).toDouble() * 0.34;
      final paint = Paint()
        ..color = PulseLinkTheme.alertRed.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, paint);
    }

    canvas.drawCircle(
      center,
      14,
      Paint()..color = PulseLinkTheme.alertRed.withOpacity(0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _DispatchRingsPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.wave != wave;
  }
}
