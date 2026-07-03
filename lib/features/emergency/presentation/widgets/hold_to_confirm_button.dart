import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/pulse_link_theme.dart';

class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({
    super.key,
    required this.committed,
    required this.onProgressChanged,
    required this.onConfirmed,
  });

  final bool committed;
  final ValueChanged<double> onProgressChanged;
  final Future<void> Function() onConfirmed;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )
      ..addListener(() {
        widget.onProgressChanged(_controller.value);
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_confirming) {
          _confirmCommitment();
        }
      });
  }

  @override
  void didUpdateWidget(covariant HoldToConfirmButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.committed && !oldWidget.committed) {
      _controller.value = 1;
    }
    if (!widget.committed && oldWidget.committed) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmCommitment() async {
    setState(() => _confirming = true);
    HapticFeedback.heavyImpact();
    try {
      await widget.onConfirmed();
    } catch (_) {
      HapticFeedback.mediumImpact();
      if (mounted && !widget.committed) {
        _controller.reverse();
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _startHold(_) {
    if (widget.committed || _confirming) return;
    HapticFeedback.selectionClick();
    _controller.forward();
  }

  void _cancelHold([dynamic _]) {
    if (widget.committed || _confirming) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _startHold,
      onTapUp: _cancelHold,
      onTapCancel: _cancelHold,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;
          final committed = widget.committed;

          return Column(
            children: [
              SizedBox(
                width: 174,
                height: 174,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        color: committed
                            ? PulseLinkTheme.successGreen
                            : PulseLinkTheme.alertRed,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: 134 - progress * 8,
                      height: 134 - progress * 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: committed
                            ? PulseLinkTheme.successGreen
                            : Color.lerp(
                                const Color(0xFF2B0408),
                                PulseLinkTheme.alertRed,
                                progress * 0.55,
                              ),
                        border: Border.all(
                          color: committed
                              ? PulseLinkTheme.successGreen
                              : PulseLinkTheme.alertRed,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (committed
                                    ? PulseLinkTheme.successGreen
                                    : PulseLinkTheme.alertRed)
                                .withOpacity(0.28 + progress * 0.38),
                            blurRadius: 22 + progress * 30,
                            spreadRadius: 3 + progress * 7,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            committed
                                ? Icons.check_circle
                                : Icons.fingerprint_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            committed ? 'ĐÃ CAM KẾT' : 'GIỮ 3S',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (!committed)
                            const Text(
                              'ĐỂ XÁC NHẬN',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 18,
                child: Text(
                  committed
                      ? 'Cam kết đã xác nhận 100%'
                      : progress == 0
                          ? 'Nhấn giữ để xác nhận'
                          : 'Đang xác nhận ${(progress * 100).round()}%',
                  style: TextStyle(
                    color: committed
                        ? PulseLinkTheme.successGreen
                        : PulseLinkTheme.alertRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
