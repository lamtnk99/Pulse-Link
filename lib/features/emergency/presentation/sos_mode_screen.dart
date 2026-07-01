import 'package:flutter/material.dart';

import '../../../app/pulse_link_controller.dart';
import '../../../core/theme/pulse_link_theme.dart';
import '../../../core/utils/vietnamese_labels.dart';
import '../domain/emergency_alert.dart';
import 'widgets/dispatch_wave_panel.dart';
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

            return Scaffold(
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
                      HoldToConfirmButton(
                        committed: state.emergencyCommitted,
                        onProgressChanged: widget.controller.updateSosIntensity,
                        onConfirmed: widget.controller.commitToEmergency,
                      ),
                      const SizedBox(height: 14),
                      _FooterCopy(committed: state.emergencyCommitted),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
              const SizedBox(height: 5),
              Text(
                'Cần gấp ${alert.unitsNeeded} đơn vị máu ${alert.requiredBloodType} ngay lúc này.',
                style: const TextStyle(
                  color: Colors.white70,
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
