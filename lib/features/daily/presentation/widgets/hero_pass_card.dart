import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/pulse_link_theme.dart';
import '../../../../core/utils/vietnamese_labels.dart';
import '../../../profile/domain/donor_profile.dart';

class HeroPassCard extends StatelessWidget {
  const HeroPassCard({
    super.key,
    required this.profile,
    required this.totalVolumeMl,
  });

  final DonorProfile profile;
  final int totalVolumeMl;

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
                const Expanded(
                  child: Text(
                    'THẺ HERO PASS PULSE LINK',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      fontSize: 12,
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
                      '${profile.totalDonations} lần hiến',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$totalVolumeMl ml đã đóng góp',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
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
