import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/pulse_link_theme.dart';
import '../../../core/utils/vietnamese_labels.dart';
import '../domain/past_donation.dart';

class DonationCertificateScreen extends StatelessWidget {
  const DonationCertificateScreen({
    super.key,
    required this.donation,
  });

  final PastDonation donation;

  @override
  Widget build(BuildContext context) {
    final verifyUrl = donation.certificateVerifyUrl;
    final typeLabel = switch (donation.donationType) {
      DonationType.sos => 'Hiến máu SOS',
      DonationType.manual => 'Ghi nhận thủ công',
      DonationType.regular => 'Hiến máu định kỳ',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chứng chỉ hiến máu'),
        actions: [
          if (verifyUrl != null && verifyUrl.isNotEmpty)
            IconButton(
              onPressed: () => launchUrl(
                Uri.parse(verifyUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'Mở bản web',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _CertificatePaper(
            donation: donation,
            typeLabel: typeLabel,
          ),
          const SizedBox(height: 16),
          if (verifyUrl != null && verifyUrl.isNotEmpty)
            _VerifyPanel(
              certificateId: donation.certificateId,
              verifyUrl: verifyUrl,
            ),
        ],
      ),
    );
  }
}

class _CertificatePaper extends StatelessWidget {
  const _CertificatePaper({
    required this.donation,
    required this.typeLabel,
  });

  final PastDonation donation;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF3),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFC99A2E), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/images/pulse_link_logo.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              Text(
                donation.certificateId,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          const Text(
            'ĐÃ XÁC THỰC',
            style: TextStyle(
              color: PulseLinkTheme.primaryRed,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chứng nhận hiến máu',
            style: TextStyle(
              color: Color(0xFF54000B),
              fontFamily: 'serif',
              fontSize: 38,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            VietnameseLabels.text(
              donation.certificateTitle ?? 'Một lần hiến máu được ghi nhận',
            ),
            style: const TextStyle(
              color: Color(0xFF475467),
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _FactBlock(
                  label: 'Ngày hiến',
                  value: DateFormat('dd/MM/yyyy').format(donation.donatedAt),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FactBlock(
                  label: 'Nhóm máu',
                  value: donation.bloodType,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FactBlock(
                  label: 'Lượng máu',
                  value: '${donation.volumeMl} ml',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FactBlock(
                  label: 'Loại hiến',
                  value: typeLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _FactBlock(
            label: 'Địa điểm',
            value: VietnameseLabels.text(donation.locationName),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE31837).withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Một lần có mặt đúng lúc có thể trở thành cơ hội sống cho người đang cần máu.',
              style: TextStyle(
                color: Color(0xFF54000B),
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactBlock extends StatelessWidget {
  const _FactBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9D7A6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF131722),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyPanel extends StatelessWidget {
  const _VerifyPanel({
    required this.certificateId,
    required this.verifyUrl,
  });

  final String certificateId;
  final String verifyUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
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
              size: 210,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            certificateId,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Đưa mã này cho người cần kiểm tra chứng chỉ. Khi quét, họ sẽ mở bản xác thực trên web.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PulseLinkTheme.mutedText,
              height: 1.4,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(verifyUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Mở bản web'),
          ),
        ],
      ),
    );
  }
}
