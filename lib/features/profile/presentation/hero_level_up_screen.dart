import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/utils/haptics.dart';
import '../../../core/utils/vietnamese_labels.dart';

/// Khoảnh khắc nghi thức khi người hiến thăng cấp Hero.
///
/// Thay vì con số lặng lẽ đổi, đây là một màn ăn mừng toàn màn hình với huy
/// hiệu tỏa sáng, hiệu ứng trồi lên và rung "thành công" — để cảm giác được
/// ghi nhận trở nên đáng nhớ.
class HeroLevelUpScreen extends StatefulWidget {
  const HeroLevelUpScreen({
    super.key,
    required this.newLevel,
    required this.badgeTitle,
    required this.onDismiss,
  });

  final String newLevel;
  final String badgeTitle;
  final VoidCallback onDismiss;

  @override
  State<HeroLevelUpScreen> createState() => _HeroLevelUpScreenState();
}

class _HeroLevelUpScreenState extends State<HeroLevelUpScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    Haptics.success();
  }

  @override
  void dispose() {
    _entry.dispose();
    _shine.dispose();
    super.dispose();
  }

  /// Màu huy hiệu theo cấp để celebration ăn khớp với tầng vừa đạt.
  ({Color base, Color glow}) _medalColors() {
    switch (widget.newLevel) {
      case 'Silver Badge':
        return (base: const Color(0xFFC0C0C0), glow: const Color(0xFFE8E8E8));
      case 'Gold Badge':
        return (base: const Color(0xFFFFD700), glow: const Color(0xFFFFE873));
      case 'Platinum Badge':
        return (base: const Color(0xFF7FD4E8), glow: const Color(0xFFB9ECF8));
      case 'Bronze Badge':
      default:
        return (base: const Color(0xFFCD7F32), glow: const Color(0xFFE8A15C));
    }
  }

  @override
  Widget build(BuildContext context) {
    final medal = _medalColors();
    final fade = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    final slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));

    return Scaffold(
      backgroundColor: const Color(0xFF03121F),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              medal.base.withOpacity(0.22),
              const Color(0xFF03121F),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: slide,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMedal(medal),
                      const SizedBox(height: 32),
                      Text(
                        'Chúc mừng thăng cấp!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: medal.glow,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        VietnameseLabels.heroLevel(widget.newLevel),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Mỗi lần bạn xắn tay áo là thêm một người có cơ hội sống. '
                        'Cảm ơn bạn đã kiên trì trên hành trình sẻ chia này.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 14.5,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: medal.base,
                            foregroundColor: const Color(0xFF03121F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: widget.onDismiss,
                          child: const Text(
                            'Tiếp tục cống hiến',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedal(({Color base, Color glow}) medal) {
    return AnimatedBuilder(
      animation: _shine,
      builder: (context, child) {
        final pulse = 1 + 0.06 * math.sin(_shine.value * 2 * math.pi);
        return Transform.scale(scale: pulse, child: child);
      },
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [medal.glow, medal.base],
          ),
          boxShadow: [
            BoxShadow(
              color: medal.base.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: 6,
            ),
          ],
        ),
        child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 66),
      ),
    );
  }
}
