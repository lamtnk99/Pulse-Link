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
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journey = widget.bloodJourney;
    final steps = journey.steps;

    return Scaffold(
      backgroundColor: PulseLinkTheme.dailyBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Concentric expanding pulsing waves around the Heart
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer expanding wave 2
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final val = _pulseController.value;
                              return Opacity(
                                opacity: (1.0 - val).clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 1.0 + (val * 0.7),
                                  child: Container(
                                    height: 76,
                                    width: 76,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFE31837).withOpacity(0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Outer expanding wave 1
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final val = _pulseController.value;
                              return Opacity(
                                opacity: (1.0 - val).clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 1.0 + (val * 0.35),
                                  child: Container(
                                    height: 76,
                                    width: 76,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFE31837).withOpacity(0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Beating Heart Icon Container
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              // Custom heartbeat rhythm calculation
                              final val = _pulseController.value;
                              double scale = 1.0;
                              if (val < 0.2) {
                                scale = 1.0 + (val * 0.9);
                              } else if (val < 0.4) {
                                scale = 1.18 - ((val - 0.2) * 0.9);
                              } else if (val < 0.6) {
                                scale = 1.0 + ((val - 0.4) * 0.6);
                              } else {
                                scale = 1.12 - ((val - 0.6) * 0.3);
                              }

                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  height: 72,
                                  width: 72,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE31837).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFE31837).withOpacity(0.5),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE31837).withOpacity(0.2),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: Color(0xFFE31837),
                                    size: 36,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'CẢM ƠN HIỆP SĨ!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hành trình giọt máu của bạn tại ${widget.hospitalName}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: PulseLinkTheme.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Breathing/Glowing Thank-You Card
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulseVal = _pulseController.value;
                        double glowOpacity = 0.04;
                        if (pulseVal < 0.5) {
                          glowOpacity = 0.04 + (pulseVal * 0.12);
                        } else {
                          glowOpacity = 0.1 - ((pulseVal - 0.5) * 0.12);
                        }

                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: PulseLinkTheme.cardBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE31837).withOpacity(glowOpacity),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE31837).withOpacity(glowOpacity * 0.4),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: Text(
                        'Sự nhanh chóng và dũng cảm của bạn đã giúp một ca cấp cứu vượt qua cơn nguy kịch. Giọt máu nhóm ${widget.bloodType} của bạn đang đi qua quy trình nghiêm ngặt dưới đây để mang lại sự sống cho người bệnh.',
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                          color: Color(0xB3FFFFFF), // white70
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Live Stepper Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'TIẾN TRÌNH THỜI GIAN THỰC',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
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
                              Column(
                                children: [
                                  // Stepper Circle Node
                                  Container(
                                    height: 24,
                                    width: 24,
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? const Color(0xFFE31837)
                                          : isCurrent
                                              ? const Color(0xFFE31837).withOpacity(0.2)
                                              : Colors.white10,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isCompleted || isCurrent
                                            ? const Color(0xFFE31837)
                                            : Colors.white24,
                                        width: 2,
                                      ),
                                    ),
                                    child: isCompleted
                                        ? const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          )
                                        : isCurrent
                                            ? AnimatedBuilder(
                                                animation: _pulseController,
                                                builder: (context, child) {
                                                  final scale = 1.0 + (_pulseController.value * 0.4);
                                                  return Transform.scale(
                                                    scale: scale,
                                                    child: Container(
                                                      margin: const EdgeInsets.all(5),
                                                      decoration: const BoxDecoration(
                                                        color: Color(0xFFE31837),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            : null,
                                  ),
                                  // Stepper Line
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
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
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
                                        const SizedBox(height: 4),
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
                                      ] else if (isCurrent) ...[
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Đang thực hiện...',
                                          style: TextStyle(
                                            color: Color(0xFFE31837),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                          ),
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
                  ],
                ),
              ),
            ),
            // Bottom Action Section
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
                  if (journey.completedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                journey.finalMessage ?? 'Hành trình giọt máu đã hoàn thành tốt đẹp.',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: widget.onClose,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE31837),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'TRỞ VỀ TRANG CHỦ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
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
    );
  }
}
