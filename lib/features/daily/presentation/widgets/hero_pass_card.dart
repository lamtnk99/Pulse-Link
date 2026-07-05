import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/pulse_link_theme.dart';
import '../../../../core/utils/vietnamese_labels.dart';
import '../../../profile/domain/donor_profile.dart';

class HeroPassCard extends StatelessWidget {
  const HeroPassCard({
    super.key,
    required this.profile,
    required this.totalVolumeMl,
    this.daysLeft,
    this.recoveryProgress,
    this.nextEligibleDate,
    this.upcomingCount,
  });

  final DonorProfile profile;
  final int totalVolumeMl;
  final int? daysLeft;
  final double? recoveryProgress;
  final DateTime? nextEligibleDate;
  final int? upcomingCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showQrSheet(context),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              PulseLinkTheme.primaryRed,
              PulseLinkTheme.deepBloodRed,
              Color(0xFF1A0003),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: PulseLinkTheme.primaryRed.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 42,
                      constraints: const BoxConstraints(maxWidth: 188),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/images/pulse_link_logo.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ),
                _Badge(title: VietnameseLabels.badgeTitle(profile.badgeTitle)),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nhóm máu',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      Text(
                        profile.bloodType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      VietnameseLabels.heroLevel(profile.heroLevel),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _HeroPassMetricItem(
                    label: 'Lần hiến',
                    value: '${profile.totalDonations}',
                    icon: Icons.favorite,
                    iconColor: const Color(0xFFFF8A80),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeroPassMetricItem(
                    label: 'Đã ghi nhận',
                    value:
                        '${NumberFormat.compact(locale: 'vi').format(totalVolumeMl)} ml',
                    icon: Icons.water_drop,
                    iconColor: const Color(0xFF80D8FF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeroPassMetricItem(
                    label: 'Điểm',
                    value: NumberFormat.compact(locale: 'vi').format(profile.points),
                    icon: Icons.stars,
                    iconColor: const Color(0xFFFFD740),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (daysLeft != null && recoveryProgress != null) ...[
              _RecoverySummary(
                daysLeft: daysLeft!,
                progress: recoveryProgress!,
                nextEligibleDate: nextEligibleDate,
                upcomingCount: upcomingCount ?? 0,
              ),
              const SizedBox(height: 14),
            ],
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mã Hero Pass',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        profile.heroPassCode,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _showQrSheet(context),
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  label: const Text('QR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQrSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Thẻ Hero Pass điện tử',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: profile.heroPassCode,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${profile.name} - ${profile.bloodType}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Xuất trình mã QR này tại quầy tiếp nhận.',
                style: TextStyle(color: PulseLinkTheme.mutedText),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _RecoverySummary extends StatelessWidget {
  const _RecoverySummary({
    required this.daysLeft,
    required this.progress,
    required this.nextEligibleDate,
    required this.upcomingCount,
  });

  final int daysLeft;
  final double progress;
  final DateTime? nextEligibleDate;
  final int upcomingCount;

  @override
  Widget build(BuildContext context) {
    final ready = daysLeft <= 0;
    final progressValue = progress.clamp(0.0, 1.0).toDouble();
    final dateLabel = nextEligibleDate == null
        ? null
        : DateFormat('dd/MM/yyyy').format(nextEligibleDate!);
    final title = ready ? 'Cơ thể đã sẵn sàng' : 'Còn $daysLeft ngày hồi phục';
    final subtitle = [
      if (!ready && dateLabel != null) 'Đủ điều kiện lại $dateLabel',
      if (ready) 'Bạn có thể chọn điểm hiến phù hợp',
      if (upcomingCount > 0) '$upcomingCount lịch đã giữ chỗ',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progressValue,
                    strokeWidth: 5,
                    color: ready ? PulseLinkTheme.successGreen : Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Icon(
                  ready
                      ? Icons.volunteer_activism_outlined
                      : Icons.self_improvement_outlined,
                  size: 20,
                  color: ready ? PulseLinkTheme.successGreen : Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium, size: 14, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPassMetricItem extends StatelessWidget {
  const _HeroPassMetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
