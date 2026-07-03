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
                      HoldToConfirmButton(
                        committed: state.emergencyCommitted,
                        onProgressChanged: widget.controller.updateSosIntensity,
                        onConfirmed: widget.controller.commitToEmergency,
                      ),
                      const SizedBox(height: 14),
                      _SosGuidanceCard(committed: state.emergencyCommitted),
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
