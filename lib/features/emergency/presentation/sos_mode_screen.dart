import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/pulse_link_controller.dart';
import '../../../app/pulse_link_state.dart';
import '../../../core/location/geo_point.dart';
import '../../../core/theme/pulse_link_theme.dart';
import '../../../core/utils/vietnamese_labels.dart';
import '../domain/emergency_alert.dart';
import '../domain/route_plan.dart';
import 'widgets/dispatch_wave_panel.dart';
import 'utils/sos_action_launcher.dart';
import 'widgets/emergency_mission_map.dart';
import 'widgets/emergency_route_map.dart';
import 'widgets/hold_to_confirm_button.dart';
import 'widgets/living_pulse_wave.dart';

class SosModeScreen extends StatefulWidget {
  const SosModeScreen({
    super.key,
    required this.controller,
  });

  final PulseLinkController controller;

  @override
  State<SosModeScreen> createState() => _SosModeScreenState();
}

class _SosModeScreenState extends State<SosModeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;
  bool _isActivatingMission = false;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _activateEmergencyMission() async {
    if (_isActivatingMission) return;

    setState(() => _isActivatingMission = true);
    try {
      await Future.wait([
        widget.controller.commitToEmergency(),
        Future<void>.delayed(const Duration(milliseconds: 850)),
      ]);
    } finally {
      if (mounted) setState(() => _isActivatingMission = false);
    }
  }

  Future<void> _callHospital(EmergencyAlert alert) async {
    final called = await callEmergencyPhone(alert.hospitalContactPhone);
    if (!called && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bệnh viện chưa có số điện thoại để gọi nhanh.'),
        ),
      );
    }
  }

  Future<void> _showRideSheet(EmergencyAlert alert) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: PulseLinkTheme.surfaceColor(context),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn cách di chuyển',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  VietnameseLabels.text(alert.hospitalName),
                  style: const TextStyle(
                    color: PulseLinkTheme.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                for (final provider in SosRideProvider.values)
                  _RideProviderTile(
                    provider: provider,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await openRideProvider(provider);
                    },
                  ),
                const SizedBox(height: 8),
                _RideProviderTile.custom(
                  icon: Icons.local_taxi_outlined,
                  title: 'Taxi hoặc người thân',
                  subtitle: 'Gọi bệnh viện để được hướng dẫn điểm đón',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _callHospital(alert);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCancelSheet() async {
    const reasons = [
      'Tôi thấy không đủ sức khỏe để di chuyển.',
      'Tôi không thể tới bệnh viện kịp thời.',
      'Tôi gặp việc khẩn cấp khác.',
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: PulseLinkTheme.surfaceColor(context),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hủy cam kết SOS',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chọn lý do gần nhất để bệnh viện điều phối người khác ngay.',
                  style: TextStyle(
                    color: PulseLinkTheme.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                for (final reason in reasons)
                  _CancelReasonTile(
                    reason: reason,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await _cancelMission(reason);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelMission(String reason) async {
    try {
      await widget.controller.cancelEmergencyCommitment(reason);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa hủy được cam kết. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return AnimatedBuilder(
          animation: _ambientController,
          builder: (context, _) {
            final state = widget.controller.state;
            final alert = state.activeAlert;
            final dispatch = state.dispatchMatch;
            final route = state.routePlan;

            if (alert == null || dispatch == null || route == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (state.sosMissionPhase == SosMissionPhase.missionActive &&
                !_isActivatingMission) {
              return _SosMissionScaffold(
                alert: alert,
                routePlan: route,
                userLocation: state.emergencyLocation,
                locationSyncError: state.locationSyncError,
                pulse: _ambientController.value,
                onDirections: () => openEmergencyDirections(alert),
                onCallHospital: () => _callHospital(alert),
                onRide: () => _showRideSheet(alert),
                onCancel: () => _showCancelSheet(),
              );
            }

            return Stack(
              children: [
                Scaffold(
                  body: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF3A050B),
                          Color(0xFF17090B),
                          PulseLinkTheme.dailyBackground,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                        children: [
                          _SosHeader(
                            alert: alert,
                            onClose: widget.controller.dismissEmergency,
                          ),
                          if (state.activeAlerts.length > 1) ...[
                            const SizedBox(height: 12),
                            _SosCaseSwitcher(
                              alerts: state.activeAlerts,
                              activeAlertId: alert.id,
                              committedAlertIds: state.committedAlertIds,
                              onSelected: (alertId) {
                                widget.controller.selectEmergencyAlert(alertId);
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          LivingPulseWave(
                            progress: _ambientController.value,
                            intensity: state.sosIntensity,
                          ),
                          const SizedBox(height: 16),
                          DispatchWavePanel(
                            alert: alert,
                            dispatchMatch: dispatch,
                            animationValue: _ambientController.value,
                          ),
                          const SizedBox(height: 14),
                          EmergencyRouteMap(
                            routePlan: route,
                            hospitalName: alert.hospitalName,
                            intensity: state.sosIntensity,
                          ),
                          const SizedBox(height: 18),
                          const _MedicalSafetyNotice(),
                          const SizedBox(height: 14),
                          HoldToConfirmButton(
                            committed: state.emergencyCommitted,
                            onProgressChanged:
                                widget.controller.updateSosIntensity,
                            onConfirmed: _activateEmergencyMission,
                          ),
                          const SizedBox(height: 14),
                          _SosGuidanceCard(committed: state.emergencyCommitted),
                          const SizedBox(height: 14),
                          _FooterCopy(committed: state.emergencyCommitted),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isActivatingMission)
                  _SosActivationOverlay(
                    alert: alert,
                    pulse: _ambientController.value,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SosActivationOverlay extends StatelessWidget {
  const _SosActivationOverlay({required this.alert, required this.pulse});

  final EmergencyAlert alert;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final scale = 0.96 + math.sin(pulse * math.pi * 2).abs() * 0.07;

    return Positioned.fill(
      child: IgnorePointer(
        child: ColoredBox(
          color: const Color(0xE60B0608),
          child: SafeArea(
            child: Center(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 240),
                tween: Tween(begin: 0, end: 1),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.92 + value * 0.08,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D0A0D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: PulseLinkTheme.alertRed.withValues(alpha: 0.52),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: PulseLinkTheme.alertRed.withValues(alpha: 0.26),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: PulseLinkTheme.alertRed,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: PulseLinkTheme.alertRed
                                    .withValues(alpha: 0.55),
                                blurRadius: 26,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emergency_share_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'ĐANG PHÁT TÍN HIỆU SOS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đang gửi cam kết và chuẩn bị chỉ đường tới ${VietnameseLabels.text(alert.hospitalName)}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFD8C6C9),
                          fontSize: 12.5,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const LinearProgressIndicator(
                        minHeight: 4,
                        color: PulseLinkTheme.alertRed,
                        backgroundColor: Color(0xFF512027),
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
}

class _MedicalSafetyNotice extends StatelessWidget {
  const _MedicalSafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medical_information_outlined,
              color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nếu đây là tình huống nguy hiểm hoặc sức khỏe bạn không ổn, hãy gọi cấp cứu/bệnh viện trước. Pulse Link chỉ hỗ trợ điều phối, mọi quyết định truyền máu thuộc về nhân viên y tế.',
              style: TextStyle(
                color: Color(0xE6FFFFFF),
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SosMissionScaffold extends StatelessWidget {
  const _SosMissionScaffold({
    required this.alert,
    required this.routePlan,
    required this.userLocation,
    required this.locationSyncError,
    required this.pulse,
    required this.onDirections,
    required this.onCallHospital,
    required this.onRide,
    required this.onCancel,
  });

  final EmergencyAlert alert;
  final RoutePlan routePlan;
  final GeoPoint? userLocation;
  final String? locationSyncError;
  final double pulse;
  final VoidCallback onDirections;
  final VoidCallback onCallHospital;
  final VoidCallback onRide;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17090B),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7A0613),
              Color(0xFF3A050B),
              Color(0xFF140709),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: _MissionPulseBackdrop(progress: pulse),
                ),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 118),
                children: [
                  _MissionHeader(
                    alert: alert,
                    routePlan: routePlan,
                    hasUserLocation: userLocation != null,
                    pulse: pulse,
                  ),
                  const SizedBox(height: 16),
                  EmergencyMissionMap(
                    alert: alert,
                    routePlan: routePlan,
                    userLocation: userLocation,
                    pulse: pulse,
                  ),
                  if (locationSyncError != null) ...[
                    const SizedBox(height: 12),
                    _MissionNotice(message: locationSyncError!),
                  ],
                  const SizedBox(height: 14),
                  _PulseGuide(alert: alert, routePlan: routePlan),
                  const SizedBox(height: 14),
                  _MissionTimeline(),
                ],
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: _MissionActionBar(
                  onDirections: onDirections,
                  onCallHospital: onCallHospital,
                  onRide: onRide,
                  onCancel: onCancel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionHeader extends StatelessWidget {
  const _MissionHeader({
    required this.alert,
    required this.routePlan,
    required this.hasUserLocation,
    required this.pulse,
  });

  final EmergencyAlert alert;
  final RoutePlan routePlan;
  final bool hasUserLocation;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HeartbeatBadge(progress: pulse),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BẠN ĐÃ NHẬN CA SOS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      VietnameseLabels.text(alert.hospitalName),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Bạn đang trên đường giúp một ca cần máu ${alert.requiredBloodType}.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          _MissionHeartbeatStrip(progress: pulse),
          const SizedBox(height: 14),
          Row(
            children: [
              _MissionStat(
                label: 'ETA',
                value: hasUserLocation
                    ? '${routePlan.estimatedMinutes} phút'
                    : 'Mở Maps',
              ),
              const SizedBox(width: 10),
              _MissionStat(
                label: 'Khoảng cách',
                value: hasUserLocation
                    ? '${routePlan.distanceKm.toStringAsFixed(1)} km'
                    : 'Chưa rõ',
              ),
              const SizedBox(width: 10),
              _MissionStat(
                label: 'Cần',
                value: '${alert.unitsNeeded} đơn vị',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionPulseBackdrop extends StatelessWidget {
  const _MissionPulseBackdrop({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MissionPulseBackdropPainter(progress: progress),
    );
  }
}

class _MissionPulseBackdropPainter extends CustomPainter {
  const _MissionPulseBackdropPainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final beat = 0.5 + 0.5 * math.sin(progress * math.pi * 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withOpacity(0.025 + beat * 0.04);

    final center = Offset(size.width * 0.82, size.height * 0.12);
    for (var i = 0; i < 4; i++) {
      final radius = 88.0 + i * 54 + beat * 16;
      canvas.drawCircle(center, radius, paint);
    }

    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = PulseLinkTheme.alertRed.withOpacity(0.05 + beat * 0.05);
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.62),
      120 + beat * 28,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MissionPulseBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _HeartbeatBadge extends StatelessWidget {
  const _HeartbeatBadge({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final beat = 0.5 + 0.5 * math.sin(progress * math.pi * 2);
    final size = 46.0 + beat * 5;

    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 46 + beat * 8,
            height: 46 + beat * 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: PulseLinkTheme.alertRed.withOpacity(0.24 + beat * 0.2),
                  blurRadius: 16 + beat * 12,
                  spreadRadius: 1 + beat * 2,
                ),
              ],
            ),
            child: Icon(
              Icons.favorite,
              color: PulseLinkTheme.alertRed,
              size: 24 + beat * 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionHeartbeatStrip extends StatelessWidget {
  const _MissionHeartbeatStrip({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      width: double.infinity,
      child: CustomPaint(
        painter: _MissionHeartbeatPainter(progress: progress),
      ),
    );
  }
}

class _MissionHeartbeatPainter extends CustomPainter {
  const _MissionHeartbeatPainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final path = Path();
    final phase = progress * math.pi * 2;

    for (var x = 0.0; x <= size.width; x += 1) {
      final t = x / size.width;
      final beatPosition = progress;
      var distance = (t - beatPosition).abs();
      if (distance > 0.5) distance = 1 - distance;

      final base = math.sin(t * math.pi * 8 + phase) * 2.5;
      final spike = math.exp(-math.pow(distance * 30, 2)) * -13;
      final rebound = math.exp(-math.pow((distance - 0.045) * 28, 2)) * 8;
      final y = centerY + base + spike + rebound;

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glow = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final stroke = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white54, Colors.white, Color(0xFFFFB3BF)],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _MissionHeartbeatPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _MissionStat extends StatelessWidget {
  const _MissionStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseGuide extends StatelessWidget {
  const _PulseGuide({
    required this.alert,
    required this.routePlan,
  });

  final EmergencyAlert alert;
  final RoutePlan routePlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PulseLinkTheme.alertRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite,
              color: PulseLinkTheme.alertRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pulse Guide',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mang CCCD/VNeID, uống vài ngụm nước và đi theo tuyến đường tới ${VietnameseLabels.text(alert.hospitalName)}. Nếu thấy người không ổn, hãy hủy cam kết để bệnh viện gọi người khác.',
                  style: const TextStyle(
                    color: Color(0xFF475467),
                    fontWeight: FontWeight.w700,
                    height: 1.42,
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

class _MissionTimeline extends StatelessWidget {
  _MissionTimeline();

  final List<({IconData icon, String title, String body})> items = const [
    (
      icon: Icons.badge_outlined,
      title: 'Chuẩn bị giấy tờ',
      body: 'Mang CCCD hoặc VNeID, ăn nhẹ nếu bạn chưa ăn.',
    ),
    (
      icon: Icons.navigation_outlined,
      title: 'Mở chỉ đường',
      body: 'Đi tới bệnh viện theo tuyến nhanh nhất bạn thấy an toàn.',
    ),
    (
      icon: Icons.local_hospital_outlined,
      title: 'Tới quầy tiếp nhận',
      body: 'Báo bạn đến theo ca SOS Pulse Link để được hướng dẫn.',
    ),
    (
      icon: Icons.verified_outlined,
      title: 'Bệnh viện xác nhận',
      body: 'Sau khi hiến xong, bệnh viện ghi nhận lượng máu và chứng chỉ.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: Colors.white, size: 21),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.body,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item != items.last)
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 1,
                    height: 18,
                    color: Colors.white24,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MissionNotice extends StatelessWidget {
  const _MissionNotice({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionActionBar extends StatelessWidget {
  const _MissionActionBar({
    required this.onDirections,
    required this.onCallHospital,
    required this.onRide,
    required this.onCancel,
  });

  final VoidCallback onDirections;
  final VoidCallback onCallHospital;
  final VoidCallback onRide;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: _MissionActionButton(
                icon: Icons.navigation,
                label: 'Chỉ đường',
                color: PulseLinkTheme.alertRed,
                onTap: onDirections,
              ),
            ),
            Expanded(
              child: _MissionActionButton(
                icon: Icons.call,
                label: 'Gọi',
                color: const Color(0xFF0F766E),
                onTap: onCallHospital,
              ),
            ),
            Expanded(
              child: _MissionActionButton(
                icon: Icons.local_taxi,
                label: 'Đặt xe',
                color: const Color(0xFF1D4ED8),
                onTap: onRide,
              ),
            ),
            Expanded(
              child: _MissionActionButton(
                icon: Icons.close,
                label: 'Hủy',
                color: const Color(0xFF64748B),
                onTap: onCancel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionActionButton extends StatelessWidget {
  const _MissionActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RideProviderTile extends StatelessWidget {
  const _RideProviderTile({
    required SosRideProvider provider,
    required this.onTap,
  })  : icon = Icons.local_taxi_outlined,
        title = null,
        subtitle = null,
        provider = provider;

  const _RideProviderTile.custom({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : provider = null;

  final SosRideProvider? provider;
  final IconData icon;
  final String? title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final provider = this.provider;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: PulseLinkTheme.alertRed.withOpacity(0.08),
        child: Icon(icon, color: PulseLinkTheme.alertRed),
      ),
      title: Text(
        provider?.label ?? title ?? '',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(provider?.subtitle ?? subtitle ?? ''),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _CancelReasonTile extends StatelessWidget {
  const _CancelReasonTile({
    required this.reason,
    required this.onTap,
  });

  final String reason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFFEE2E2),
        child: Icon(Icons.close, color: PulseLinkTheme.alertRed),
      ),
      title: Text(
        reason,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SosCaseSwitcher extends StatelessWidget {
  const _SosCaseSwitcher({
    required this.alerts,
    required this.activeAlertId,
    required this.committedAlertIds,
    required this.onSelected,
  });

  final List<EmergencyAlert> alerts;
  final String activeAlertId;
  final Set<String> committedAlertIds;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final alert = alerts[index];
          final selected = alert.id == activeAlertId;
          final committed = committedAlertIds.contains(alert.id);

          return InkWell(
            onTap: () => onSelected(alert.id),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 210,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? PulseLinkTheme.alertRed
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${alert.requiredBloodType} · ${alert.unitsNeeded} đơn vị',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (committed)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF34D399),
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    VietnameseLabels.text(alert.hospitalName),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SosHeader extends StatelessWidget {
  const _SosHeader({
    required this.alert,
    required this.onClose,
  });

  final EmergencyAlert alert;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: PulseLinkTheme.alertRed.withOpacity(0.18),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: PulseLinkTheme.alertRed.withOpacity(0.35),
                blurRadius: 22,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_active,
            color: PulseLinkTheme.alertRed,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BÁO ĐỘNG ĐỎ ${alert.level.label.toUpperCase()}',
                style: const TextStyle(
                  color: PulseLinkTheme.alertRed,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                VietnameseLabels.text(alert.hospitalName),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 6),
              // Đóng khung quanh con người: người cần máu, không phải dữ liệu.
              Text(
                'Một người bệnh đang cần nhóm máu ${alert.requiredBloodType} của bạn để giành lại sự sống.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cần gấp ${alert.unitsNeeded} đơn vị · chỉ bạn ở gần mới kịp.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          tooltip: 'Đóng SOS',
        ),
      ],
    );
  }
}

class _FooterCopy extends StatelessWidget {
  const _FooterCopy({
    required this.committed,
  });

  final bool committed;

  @override
  Widget build(BuildContext context) {
    return Text(
      committed
          ? 'Cam kết đã gửi. Bệnh viện hiện có thể theo dõi trạng thái điều phối của bạn.'
          : 'Nhấn giữ liên tục 3 giây để tránh xác nhận nhầm trong tình huống khẩn cấp.',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: PulseLinkTheme.mutedText,
        fontSize: 12,
        height: 1.45,
      ),
    );
  }
}

class _SosGuidanceCard extends StatelessWidget {
  const _SosGuidanceCard({
    required this.committed,
  });

  final bool committed;

  @override
  Widget build(BuildContext context) {
    final items = committed
        ? [
            'Đi theo tuyến đường được gợi ý và giữ điện thoại bên mình.',
            'Khi tới nơi, báo với quầy tiếp nhận rằng bạn đến theo ca SOS Pulse Link.',
            'Nếu thấy không khỏe trên đường đi, dừng lại và liên hệ bệnh viện.',
          ]
        : [
            'Chỉ xác nhận khi bạn thật sự có thể di chuyển ngay.',
            'Nếu vừa ốm, thiếu ngủ hoặc thấy không ổn, hãy bỏ qua ca này.',
            'Một xác nhận chắc chắn giúp bệnh viện điều phối chính xác hơn.',
          ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            committed ? 'Bạn đã nhận ca này' : 'Trước khi xác nhận',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF34D399),
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.35,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (item != items.last) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}
