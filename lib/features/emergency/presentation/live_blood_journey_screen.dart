import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/pulse_link_theme.dart';
import '../../daily/domain/blood_journey.dart';

class LiveBloodJourneyScreen extends StatefulWidget {
  const LiveBloodJourneyScreen({
    super.key,
    required this.bloodJourney,
    required this.hospitalName,
    required this.bloodType,
    required this.onClose,
  });

  final BloodJourney bloodJourney;
  final String hospitalName;
  final String bloodType;
  final VoidCallback onClose;

  @override
  State<LiveBloodJourneyScreen> createState() => _LiveBloodJourneyScreenState();
}

class _LiveBloodJourneyScreenState extends State<LiveBloodJourneyScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _floatController;
  late final AnimationController _particleController;

  // Floating particles for emotional ambiance
  late final List<_FloatingParticle> _particles;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    final rng = Random(42);
    _particles = List.generate(12, (i) {
      return _FloatingParticle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 2.0 + rng.nextDouble() * 4.0,
        speed: 0.3 + rng.nextDouble() * 0.7,
        opacity: 0.08 + rng.nextDouble() * 0.18,
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journey = widget.bloodJourney;
    final steps = journey.steps;

    return Scaffold(
      backgroundColor: PulseLinkTheme.dailyBackground,
      body: Stack(
        children: [
          // Floating ambient particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AmbientParticlePainter(
                    particles: _particles,
                    animValue: _particleController.value,
                  ),
                );
              },
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),

                        // ═══════════════════════════════════════════
                        // HERO SECTION: Beating Heart with Pulse Waves
                        // ═══════════════════════════════════════════
                        SizedBox(
                          height: 140,
                          width: 140,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Wave ring 3 (outermost)
                              _buildExpandingWave(delay: 0.0, maxScale: 1.8),
                              // Wave ring 2
                              _buildExpandingWave(delay: 0.33, maxScale: 1.5),
                              // Wave ring 1 (closest)
                              _buildExpandingWave(delay: 0.66, maxScale: 1.25),
                              // Beating Heart Core
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final val = _pulseController.value;
                                  // Realistic heartbeat: two beats then rest
                                  double scale;
                                  if (val < 0.12) {
                                    scale = 1.0 + (val / 0.12) * 0.22;
                                  } else if (val < 0.24) {
                                    scale = 1.22 - ((val - 0.12) / 0.12) * 0.22;
                                  } else if (val < 0.36) {
                                    scale = 1.0 + ((val - 0.24) / 0.12) * 0.15;
                                  } else if (val < 0.48) {
                                    scale = 1.15 - ((val - 0.36) / 0.12) * 0.15;
                                  } else {
                                    scale = 1.0;
                                  }

                                  final glowIntensity = (scale - 1.0).clamp(0.0, 1.0);

                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      height: 80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          colors: [
                                            const Color(0xFFE31837).withOpacity(0.25 + glowIntensity * 0.15),
                                            const Color(0xFFE31837).withOpacity(0.05),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFE31837).withOpacity(0.6),
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE31837).withOpacity(0.15 + glowIntensity * 0.2),
                                            blurRadius: 20 + glowIntensity * 15,
                                            spreadRadius: 4 + glowIntensity * 6,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.favorite_rounded,
                                        color: Color(0xFFE31837),
                                        size: 38,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ═══════════════════════════════════════════
                        // GRATITUDE HEADLINE
                        // ═══════════════════════════════════════════
                        const Text(
                          'CẢM ƠN BẠN,\nHIỆP SĨ CỨU NGƯỜI!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Subtitle with hospital context
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE31837).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFFE31837).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_hospital_rounded,
                                color: Color(0xFFE31837),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${widget.hospitalName} · Nhóm ${widget.bloodType}',
                                  style: const TextStyle(
                                    color: Color(0xFFE31837),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ═══════════════════════════════════════════
                        // HUMANISTIC QUOTE CARD (breathing glow)
                        // ═══════════════════════════════════════════
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final v = _pulseController.value;
                            final glow = v < 0.5
                                ? 0.06 + v * 0.14
                                : 0.13 - (v - 0.5) * 0.14;

                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: PulseLinkTheme.cardBackground,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE31837).withOpacity(glow),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE31837).withOpacity(glow * 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: child,
                            );
                          },
                          child: Column(
                            children: [
                              // Quote icon
                              const Icon(
                                Icons.format_quote_rounded,
                                color: Color(0xFFE31837),
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Giọt máu nhóm ${widget.bloodType} của bạn chính là sợi dây nối liền sự sống. '
                                'Nhờ lòng dũng cảm và sự nhanh nhẹn của bạn, một người bệnh đang được tiếp thêm hy vọng ngay lúc này.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xB3FFFFFF),
                                  fontSize: 13,
                                  height: 1.65,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Impact stat badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE31837).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.people_alt_rounded,
                                      color: Color(0xFFE31837),
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Mỗi lần hiến máu có thể cứu đến 3 mạng người',
                                        style: TextStyle(
                                          color: Color(0xFFE31837),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ═══════════════════════════════════════════
                        // LIVE JOURNEY STEPPER
                        // ═══════════════════════════════════════════
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) {
                                  final op = 0.5 + _pulseController.value * 0.5;
                                  return Container(
                                    height: 8,
                                    width: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE31837).withOpacity(op),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'TIẾN TRÌNH THỜI GIAN THỰC',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Stepper List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: steps.length,
                          itemBuilder: (context, index) {
                            final step = steps[index];
                            final isCompleted = step.completed || step.occurredAt != null;
                            final isCurrent = journey.currentStep == step.key;
                            final showLine = index < steps.length - 1;

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Left column: node + line
                                  Column(
                                    children: [
                                      // Circle node
                                      _buildStepNode(isCompleted, isCurrent),
                                      // Connecting line
                                      if (showLine)
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            color: isCompleted
                                                ? const Color(0xFFE31837)
                                                : Colors.white10,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  // Right column: label + timestamp
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 28),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            step.label,
                                            style: TextStyle(
                                              color: isCompleted || isCurrent
                                                  ? Colors.white
                                                  : Colors.white38,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          if (isCompleted && step.occurredAt != null) ...[
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.access_time_rounded,
                                                  color: PulseLinkTheme.mutedText,
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  DateFormat('HH:mm - dd/MM/yyyy').format(
                                                    step.occurredAt!.toLocal(),
                                                  ),
                                                  style: const TextStyle(
                                                    color: PulseLinkTheme.mutedText,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ] else if (isCurrent) ...[
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                SizedBox(
                                                  height: 12,
                                                  width: 12,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 1.5,
                                                    color: const Color(0xFFE31837).withOpacity(0.8),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Đang thực hiện...',
                                                  style: TextStyle(
                                                    color: Color(0xFFE31837),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // ═══════════════════════════════════════════
                // BOTTOM ACTION BAR
                // ═══════════════════════════════════════════
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: PulseLinkTheme.cardBackground,
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Lá thư cảm ơn từ người nhận — payload cảm xúc cao nhất của hành trình.
                      if (journey.completedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _GratitudeLetterCard(
                            message: journey.finalMessage ??
                                'Giọt máu của bạn đã cứu sống người bệnh thành công!',
                            isReserve: journey.destinationType == 'reserve',
                          ),
                        ),
                      // Close button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE31837), Color(0xFFB91C1C)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE31837).withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onClose,
                              borderRadius: BorderRadius.circular(16),
                              child: const Center(
                                child: Text(
                                  'Trở về trang chủ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Expanding concentric wave ring with stagger
  // ─────────────────────────────────────────────
  Widget _buildExpandingWave({required double delay, required double maxScale}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final raw = (_pulseController.value + delay) % 1.0;
        final opacity = (1.0 - raw).clamp(0.0, 0.6);
        final scale = 1.0 + raw * (maxScale - 1.0);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE31837).withOpacity(0.35),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Stepper circle node
  // ─────────────────────────────────────────────
  Widget _buildStepNode(bool isCompleted, bool isCurrent) {
    if (isCompleted) {
      return Container(
        height: 28,
        width: 28,
        decoration: const BoxDecoration(
          color: Color(0xFFE31837),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x40E31837),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
      );
    }

    if (isCurrent) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final val = _pulseController.value;
          final glowOp = 0.2 + val * 0.3;

          return Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFE31837).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE31837),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE31837).withOpacity(glowOp),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Container(
                height: 8,
                width: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFE31837),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      );
    }

    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Floating ambient particles for emotional ambiance
// ═══════════════════════════════════════════════════
class _FloatingParticle {
  _FloatingParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });

  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
}

class _AmbientParticlePainter extends CustomPainter {
  _AmbientParticlePainter({
    required this.particles,
    required this.animValue,
  });

  final List<_FloatingParticle> particles;
  final double animValue;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final yOffset = (p.y + animValue * p.speed) % 1.1 - 0.05;
      final xWobble = p.x + sin(animValue * 2 * pi * p.speed) * 0.03;

      final paint = Paint()
        ..color = const Color(0xFFE31837).withOpacity(p.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(xWobble * size.width, yOffset * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_AmbientParticlePainter oldDelegate) {
    return oldDelegate.animValue != animValue;
  }
}

// ═══════════════════════════════════════════════════
// Lá thư cảm ơn từ người nhận / đội ngũ y tế (AI cá nhân hóa).
// Trình bày như một bức thư tay ấm áp thay cho banner trạng thái.
// ═══════════════════════════════════════════════════
class _GratitudeLetterCard extends StatelessWidget {
  const _GratitudeLetterCard({
    required this.message,
    required this.isReserve,
  });

  final String message;
  final bool isReserve;

  @override
  Widget build(BuildContext context) {
    final sender = isReserve ? 'Đội ngũ y tế' : 'Gia đình người bệnh';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B6B).withOpacity(0.16),
            const Color(0xFFE31837).withOpacity(0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE31837).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE31837).withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mail_rounded, color: Color(0xFFE31837), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lời cảm ơn gửi tới bạn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Từ $sender',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote_rounded, size: 18, color: Color(0xFFFF9E9E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
