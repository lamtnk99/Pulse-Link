import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/pulse_link_controller.dart';
import '../../../core/theme/pulse_link_theme.dart';
import '../domain/community_impact.dart';

/// Thẻ tác động tập thể + tường tri ân — nuôi cảm giác "thuộc về": người dùng
/// thấy mình là một phần của điều gì đó lớn hơn bản thân.
class CommunityImpactCard extends StatefulWidget {
  const CommunityImpactCard({super.key, required this.controller});

  final PulseLinkController controller;

  @override
  State<CommunityImpactCard> createState() => _CommunityImpactCardState();
}

class _CommunityImpactCardState extends State<CommunityImpactCard> {
  CommunityImpact? _impact;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final impact = await widget.controller.communityImpactService.getImpact();
      if (!mounted) return;
      setState(() {
        _impact = impact;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final impact = _impact;
    if (!_loaded || impact == null || !impact.hasData) {
      return const SizedBox.shrink();
    }

    final isDark = PulseLinkTheme.isDark(context);
    final formatter = NumberFormat.decimalPattern('vi_VN');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PulseLinkTheme.primaryRed.withOpacity(isDark ? 0.18 : 0.08),
            PulseLinkTheme.primaryRed.withOpacity(isDark ? 0.08 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PulseLinkTheme.primaryRed.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.diversity_1_rounded, color: PulseLinkTheme.primaryRed, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cộng đồng ${impact.monthLabel.toLowerCase()}',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: PulseLinkTheme.textColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 13, height: 1.5, color: PulseLinkTheme.mutedColor(context)),
              children: [
                const TextSpan(text: 'Bạn không đơn độc — '),
                TextSpan(
                  text: '${formatter.format(impact.activeDonors)} hiệp sĩ',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: PulseLinkTheme.primaryRed),
                ),
                const TextSpan(text: ' đã cùng cho đi tháng này.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat(context, formatter.format(impact.donationsThisMonth), 'lượt hiến'),
              _statDivider(),
              _stat(context, '${formatter.format(impact.volumeMlThisMonth)} mL', 'số lượng ML'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(context, formatter.format(impact.campaignDonationsCount), 'lượt quyên góp'),
              _statDivider(),
              _stat(context, '${formatter.format(impact.totalDonatedAmount)}đ', 'tổng số tiền quyên góp'),
            ],
          ),
          if (impact.gratitudeWall.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: impact.gratitudeWall.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _noteCard(context, impact.gratitudeWall[index], isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: PulseLinkTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, height: 1.2, color: PulseLinkTheme.mutedColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: PulseLinkTheme.primaryRed.withOpacity(0.15),
    );
  }

  Widget _noteCard(BuildContext context, GratitudeNote note, bool isDark) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PulseLinkTheme.surfaceColor(context).withOpacity(isDark ? 0.5 : 1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PulseLinkTheme.subtleBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '“${note.message}”',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontStyle: FontStyle.italic,
                color: PulseLinkTheme.textColor(context).withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '— ${note.donorName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: PulseLinkTheme.primaryRed,
            ),
          ),
        ],
      ),
    );
  }
}
