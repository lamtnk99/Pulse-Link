import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/donation_campaign.dart';
import 'donation_palette.dart';

/// Kết quả một lượt quyên góp, dùng để dựng màn cảm ơn.
class DonationResult {
  const DonationResult({
    required this.isCash,
    required this.amount,
    required this.points,
    required this.donorName,
    this.message,
    this.isAnonymous = false,
    this.isPending = false,
  });

  final bool isCash;
  final double amount;
  final int points;
  final String donorName;
  final String? message;
  final bool isAnonymous;

  /// Với tiền mặt, giao dịch chờ webhook xác nhận nên chưa "chắc chắn" hoàn tất.
  final bool isPending;
}

/// Khoảnh khắc cảm ơn sau khi quyên góp — đỉnh cảm xúc của cả luồng.
///
/// Thay cho một SnackBar lạnh lẽo, màn này gọi tên người đóng góp, nêu tác động
/// cụ thể vừa tạo ra và mời họ lan tỏa tiếp.
class DonationThankYouScreen extends StatefulWidget {
  const DonationThankYouScreen({
    super.key,
    required this.campaign,
    required this.result,
    this.onViewLeaderboard,
  });

  final DonationCampaign campaign;
  final DonationResult result;
  final VoidCallback? onViewLeaderboard;

  @override
  State<DonationThankYouScreen> createState() => _DonationThankYouScreenState();
}

class _DonationThankYouScreenState extends State<DonationThankYouScreen>
    with TickerProviderStateMixin {
  late final AnimationController _heartController;
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    // Nhịp đập trái tim nhẹ, lặp lại.
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    // Hiệu ứng nội dung trồi lên khi mở màn.
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _heartController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  String get _firstName {
    if (widget.result.isAnonymous) return 'Hiệp sĩ';
    final name = widget.result.donorName.trim();
    if (name.isEmpty) return 'Hiệp sĩ';
    return name.split(RegExp(r'\s+')).last;
  }

  /// Câu nêu tác động cụ thể vừa tạo ra, nếu chiến dịch có đơn vị quy đổi.
  String? get _impactLine {
    final c = widget.campaign;
    if (!c.hasImpactUnit) return null;
    final units = widget.result.isCash
        ? c.impactUnitsForAmount(widget.result.amount)
        : c.impactUnitsForPoints(widget.result.points);
    if (units <= 0) return null;
    return 'Món quà của bạn tương đương $units ${c.impactUnit}';
  }

  String get _contributionText {
    if (widget.result.isCash) {
      return '${NumberFormat('#,###').format(widget.result.amount)}đ';
    }
    return '${widget.result.points} điểm Hero';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final impact = _impactLine;

    final fade = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF3A0A14), const Color(0xFF0F172A)]
                : [DonationPalette.coral.withOpacity(0.16), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Nút đóng
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: Icon(Icons.close_rounded, color: DonationPalette.mutedText(isDark)),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: slide,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeart(),
                          const SizedBox(height: 28),
                          Text(
                            'Cảm ơn $_firstName',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: DonationPalette.strongText(isDark),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.result.isPending
                                ? 'Chúng tôi đang chờ xác nhận thanh toán. Ngay khi hoàn tất, món quà của bạn sẽ đến tay những người đang cần.'
                                : 'Bạn vừa trao đi một tia hy vọng. Tấm lòng của bạn sẽ chạm đến những người đang cần nhất.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.6,
                              color: DonationPalette.mutedText(isDark),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildContributionChip(isDark),
                          if (impact != null) ...[
                            const SizedBox(height: 14),
                            _buildImpactCard(isDark, impact),
                          ],
                          if (widget.result.message != null &&
                              widget.result.message!.trim().isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildMessageCard(isDark),
                          ],
                          const SizedBox(height: 32),
                          _buildActions(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeart() {
    return AnimatedBuilder(
      animation: _heartController,
      builder: (context, child) {
        final scale = 1 + 0.08 * math.sin(_heartController.value * math.pi);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          gradient: DonationPalette.warmGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: DonationPalette.primary.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 52),
      ),
    );
  }

  Widget _buildContributionChip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: DonationPalette.primary.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: DonationPalette.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.result.isCash ? Icons.volunteer_activism_rounded : Icons.stars_rounded,
            size: 18,
            color: DonationPalette.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Đã gửi $_contributionText',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: DonationPalette.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard(bool isDark, String impact) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DonationPalette.amber.withOpacity(isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.eco_rounded, color: DonationPalette.amber, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              impact,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: DonationPalette.strongText(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DonationPalette.surface(isDark).withOpacity(isDark ? 0.5 : 1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DonationPalette.subtleBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, size: 16, color: DonationPalette.amber),
              const SizedBox(width: 6),
              Text(
                'Lời chúc của bạn',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: DonationPalette.mutedText(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.result.message!.trim(),
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: DonationPalette.strongText(isDark).withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: DonationPalette.warmGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.of(context).maybePop();
                widget.onViewLeaderboard?.call();
              },
              child: const Text(
                'Xem bảng vàng tri ân',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(
            'Quay lại chiến dịch',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DonationPalette.mutedText(isDark),
            ),
          ),
        ),
      ],
    );
  }
}
