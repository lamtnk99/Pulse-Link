import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pulse_link_theme.dart';
import '../../../../core/utils/vietnamese_labels.dart';
import '../../domain/past_donation.dart';
import '../donation_certificate_screen.dart';

class DonationHistoryTile extends StatelessWidget {
  const DonationHistoryTile({
    super.key,
    required this.donation,
  });

  final PastDonation donation;

  @override
  Widget build(BuildContext context) {
    final donationType = _donationTypeLabel(donation.donationType);
    final verifyUrl = donation.certificateVerifyUrl;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseLinkTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PulseLinkTheme.subtleBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: PulseLinkTheme.primaryRed.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  donation.donationType == DonationType.sos
                      ? Icons.sos
                      : Icons.workspace_premium_outlined,
                  color: PulseLinkTheme.primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      VietnameseLabels.text(
                        donation.certificateTitle ?? donationType,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: PulseLinkTheme.textColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      VietnameseLabels.text(donation.locationName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: PulseLinkTheme.mutedColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${donation.volumeMl} ml',
                    style: TextStyle(
                      color: PulseLinkTheme.textColor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    donation.bloodType,
                    style: const TextStyle(
                      color: PulseLinkTheme.primaryRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (donation.bloodJourney != null) ...[
            const SizedBox(height: 12),
            _BloodJourneyPanel(donation: donation),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CertificateChip(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('dd/MM/yyyy').format(donation.donatedAt),
              ),
              _CertificateChip(
                icon: Icons.verified_outlined,
                label: donation.certificateId,
              ),
              _CertificateChip(
                icon: donation.donationType == DonationType.sos
                    ? Icons.emergency_outlined
                    : Icons.favorite_border,
                label: donationType,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (donation.resultSummary != null &&
              donation.resultSummary!.isNotEmpty)
            Text(
              VietnameseLabels.text(donation.resultSummary!),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PulseLinkTheme.successGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Text(
              'Đang chờ kết quả xét nghiệm',
              style: TextStyle(
                color: PulseLinkTheme.mutedColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  donation.certificateIssuedAt == null
                      ? 'Chứng chỉ đã được ghi nhận'
                      : 'Cấp ngày ${DateFormat('dd/MM/yyyy').format(donation.certificateIssuedAt!)}',
                  style: TextStyle(
                    color: PulseLinkTheme.mutedColor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DonationCertificateScreen(
                      donation: donation,
                    ),
                  ),
                ),
                icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                label: const Text('Chứng chỉ'),
              ),
              TextButton.icon(
                onPressed: verifyUrl == null || verifyUrl.isEmpty
                    ? null
                    : () => _showCertificate(context, verifyUrl),
                icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                label: const Text('QR'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _donationTypeLabel(DonationType type) {
    return switch (type) {
      DonationType.sos => 'Hiến máu SOS',
      DonationType.manual => 'Ghi nhận thủ công',
      DonationType.regular => 'Hiến máu định kỳ',
    };
  }

  Future<void> _showCertificate(BuildContext context, String verifyUrl) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: PulseLinkTheme.surfaceColor(context),
          title: const Text(
            'QR chứng chỉ',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: QrImageView(
                  data: verifyUrl,
                  version: QrVersions.auto,
                  size: 190,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                donation.certificateId,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PulseLinkTheme.textColor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Quét mã này để mở bản chứng chỉ xác thực.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PulseLinkTheme.mutedColor(context),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DonationCertificateScreen(
                      donation: donation,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Xem chứng chỉ'),
            ),
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(verifyUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Mở web'),
            ),
          ],
        );
      },
    );
  }
}

class _BloodJourneyPanel extends StatelessWidget {
  const _BloodJourneyPanel({
    required this.donation,
  });

  final PastDonation donation;

  @override
  Widget build(BuildContext context) {
    final journey = donation.bloodJourney!;
    final message = journey.publishedAt == null
        ? 'Bệnh viện đang cập nhật hành trình giọt máu của bạn.'
        : journey.finalMessage ?? 'Hành trình giọt máu đã được ghi nhận.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PulseLinkTheme.primaryRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PulseLinkTheme.primaryRed.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hành trình giọt máu',
            style: TextStyle(
              color: PulseLinkTheme.primaryRed,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...journey.steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    step.completed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: step.completed
                        ? PulseLinkTheme.successGreen
                        : PulseLinkTheme.mutedColor(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      VietnameseLabels.text(step.label),
                      style: TextStyle(
                        color: PulseLinkTheme.textColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            VietnameseLabels.text(message),
            style: TextStyle(
              color: PulseLinkTheme.mutedColor(context),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateChip extends StatelessWidget {
  const _CertificateChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: PulseLinkTheme.isDark(context)
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PulseLinkTheme.subtleBorderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: PulseLinkTheme.mutedColor(context)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: PulseLinkTheme.mutedColor(context),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
