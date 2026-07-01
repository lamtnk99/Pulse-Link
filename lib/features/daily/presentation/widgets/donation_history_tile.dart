import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/pulse_link_theme.dart';
import '../../../../core/utils/vietnamese_labels.dart';
import '../../domain/past_donation.dart';

class DonationHistoryTile extends StatelessWidget {
  const DonationHistoryTile({
    super.key,
    required this.donation,
  });

  final PastDonation donation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PulseLinkTheme.primaryRed.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.water_drop,
              color: PulseLinkTheme.primaryRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                  VietnameseLabels.text(donation.locationName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(donation.donatedAt)} - ${donation.certificateId}',
                  style: const TextStyle(
                    color: PulseLinkTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${donation.volumeMl} ml',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                VietnameseLabels.verificationStatus(donation.status.name),
                style: TextStyle(
                  color: donation.status == DonationVerificationStatus.verified
                      ? PulseLinkTheme.successGreen
                      : Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
