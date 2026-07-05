import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/donation_campaign.dart';
import '../../../app/pulse_link_controller.dart';
import 'donation_detail_screen.dart';
import 'donation_palette.dart';

class DonationCampaignsScreen extends StatefulWidget {
  const DonationCampaignsScreen({
    super.key,
    required this.controller,
  });

  final PulseLinkController controller;

  @override
  State<DonationCampaignsScreen> createState() => _DonationCampaignsScreenState();
}

class _DonationCampaignsScreenState extends State<DonationCampaignsScreen> {
  List<DonationCampaign> _campaigns = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final campaigns = await widget.controller.donationFundService.getCampaigns();
      setState(() {
        _campaigns = campaigns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách chiến dịch quyên góp. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đồng hành quyên góp',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCampaigns,
        color: const Color(0xFFE31837),
        child: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: DonationPalette.primary),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 64, color: DonationPalette.primary),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: DonationPalette.mutedText(isDark)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCampaigns,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DonationPalette.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return _buildCampaignList(_campaigns, isDark: isDark);
  }

  Widget _buildCampaignList(List<DonationCampaign> list, {required bool isDark}) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Center(
            child: Column(
              children: [
                Icon(Icons.favorite_border_rounded, size: 44, color: DonationPalette.primary.withOpacity(0.6)),
                const SizedBox(height: 12),
                Text(
                  'Hiện chưa có chiến dịch nào đang diễn ra.\nHãy quay lại sau nhé!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DonationPalette.mutedText(isDark), fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final campaign = list[index];
        return _buildCampaignCard(campaign, isDark);
      },
    );
  }

  Widget _buildCampaignCard(DonationCampaign campaign, bool isDark) {
    // Thanh tiến độ chính: ưu tiên mục tiêu tài chính nếu có, không thì mục tiêu điểm.
    // (Mọi chiến dịch đều nhận cả hai; đây chỉ là chỉ số hiển thị nổi bật nhất.)
    final showFinancial = campaign.hasFinancialGoal;
    final progress = showFinancial ? campaign.financialProgress : campaign.pointsProgress;
    final progressPercent = (progress * 100).round();

    // Framing tích cực, hướng hành động: nêu phần còn thiếu thay vì chỉ "tiến độ".
    final remaining = showFinancial
        ? campaign.targetAmount - campaign.currentAmount
        : (campaign.targetPoints - campaign.currentPoints).toDouble();
    final remainingText = showFinancial
        ? '${_formatCurrency(remaining < 0 ? 0 : remaining)}đ'
        : '${remaining < 0 ? 0 : remaining.toInt()} điểm';

    final urgency = DonationPalette.urgency(campaign.urgencyLevel);
    final daysLeft = campaign.daysLeft;
    final beneficiary = (campaign.beneficiaryName ?? '').trim();
    // Ưu tiên kể câu chuyện; nếu chưa có thì rơi về mô tả.
    final storyLine = campaign.hasStory ? campaign.beneficiaryStory!.trim() : campaign.description;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => DonationDetailScreen(
              controller: widget.controller,
              campaignId: campaign.id,
            ),
          ),
        ).then((_) => _loadCampaigns());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: DonationPalette.surface(isDark),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: DonationPalette.subtleBorder(isDark)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh + overlay + badge cấp thiết + tên người thụ hưởng
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: campaign.imageUrl != null
                      ? Image.network(
                          campaign.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      ),
                    ),
                  ),
                ),
                if (urgency != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _CampaignBadge(icon: urgency.icon, label: urgency.label, color: urgency.color),
                  ),
                if (daysLeft != null && daysLeft <= 30)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _CampaignBadge(
                      icon: Icons.schedule_rounded,
                      label: daysLeft <= 0 ? 'Sắp kết thúc' : 'Còn $daysLeft ngày',
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
                if (beneficiary.isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: Row(
                      children: [
                        const Icon(Icons.favorite_rounded, size: 15, color: Colors.white),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Vì $beneficiary',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                      color: DonationPalette.strongText(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    storyLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: DonationPalette.mutedText(isDark),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress == 0 ? null : progress,
                      backgroundColor: DonationPalette.primary.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(DonationPalette.primary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đã cùng góp $progressPercent%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: DonationPalette.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              remaining <= 0 ? 'Đã về đích, cảm ơn cộng đồng!' : 'Còn thiếu $remainingText để về đích',
                              style: TextStyle(fontSize: 12, color: DonationPalette.mutedText(isDark)),
                            ),
                          ],
                        ),
                      ),
                      if (campaign.donorCount > 0)
                        Row(
                          children: [
                            Icon(Icons.people_alt_rounded, size: 14, color: DonationPalette.coral),
                            const SizedBox(width: 4),
                            Text(
                              '${campaign.donorCount}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: DonationPalette.strongText(isDark),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: DonationPalette.warmGradient),
      child: Center(
        child: Icon(Icons.favorite_rounded, color: Colors.white70, size: 44),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return '${millions.toStringAsFixed(millions % 1 == 0 ? 0 : 1)} triệu';
    }
    if (amount >= 1000) {
      return '${NumberFormat('#,###').format(amount)}';
    }
    return amount.toStringAsFixed(0);
  }
}

class _CampaignBadge extends StatelessWidget {
  const _CampaignBadge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
