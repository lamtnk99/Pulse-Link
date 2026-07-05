import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/pulse_link_controller.dart';
import '../domain/donation_campaign.dart';
import '../domain/campaign_donation.dart';
import 'donation_palette.dart';
import 'donation_thank_you_screen.dart';

class DonationDetailScreen extends StatefulWidget {
  const DonationDetailScreen({
    super.key,
    required this.controller,
    required this.campaignId,
  });

  final PulseLinkController controller;
  final String campaignId;

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DonationCampaign? _campaign;
  List<CampaignDonation> _leaderboard = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDetails(showLoading: true);
    
    // Realtime Polling: updates details every 5 seconds to ensure real-time progress
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadDetails(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails({required bool showLoading}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final detail = await widget.controller.donationFundService.getCampaignDetail(widget.campaignId);
      if (mounted) {
        setState(() {
          _campaign = detail['campaign'] as DonationCampaign;
          _leaderboard = List<CampaignDonation>.from(detail['leaderboard'] as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && showLoading) {
        setState(() {
          _error = 'Không thể tải thông tin dự án. Vui lòng quay lại sau.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết chiến dịch')),
        body: const Center(
          child: CircularProgressIndicator(color: DonationPalette.primary),
        ),
      );
    }

    if (_error != null || _campaign == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết chiến dịch')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: DonationPalette.primary),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Không tìm thấy thông tin chiến dịch.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final campaign = _campaign!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    campaign.imageUrl != null
                        ? Image.network(campaign.imageUrl!, fit: BoxFit.cover)
                        : Container(color: Colors.red.withOpacity(0.1)),
                    // Gradient overlay
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black54, Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Glassmorphic Progress Header
            _buildProgressCard(campaign, isDark),
            // Tab Header
            TabBar(
              controller: _tabController,
              labelColor: DonationPalette.primary,
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
              indicatorColor: DonationPalette.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              tabs: const [
                Tab(text: 'Câu chuyện'),
                Tab(text: 'Bảng vàng tri ân'),
              ],
            ),
            // Tab View Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAboutTab(campaign, isDark),
                  _buildLeaderboardTab(isDark),
                ],
              ),
            ),
            // Donate Bottom Action Button
            _buildBottomActionBar(campaign),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(DonationCampaign campaign, bool isDark) {
    final showCash = campaign.isFinancial;
    final showPoints = campaign.isPoints;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campaign.title,
            style: TextStyle(
              fontSize: 16.5,
              height: 1.3,
              fontWeight: FontWeight.w800,
              color: DonationPalette.strongText(isDark),
            ),
          ),
          const SizedBox(height: 16),
          if (showCash) ...[
            _buildProgressRow(
              label: 'Tấm lòng tài chính',
              current: campaign.currentAmount,
              target: campaign.targetAmount,
              progress: campaign.financialProgress,
              isCash: true,
              campaign: campaign,
            ),
            if (showPoints) const SizedBox(height: 16),
          ],
          if (showPoints)
            _buildProgressRow(
              label: 'Điểm Hero đồng hành',
              current: campaign.currentPoints.toDouble(),
              target: campaign.targetPoints.toDouble(),
              progress: campaign.pointsProgress,
              isCash: false,
              campaign: campaign,
            ),
          // Social proof: cộng đồng đang cùng chung tay.
          if (campaign.donorCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: DonationPalette.coral.withOpacity(isDark ? 0.14 : 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_alt_rounded, size: 18, color: DonationPalette.coral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 13, color: DonationPalette.strongText(isDark)),
                        children: [
                          TextSpan(
                            text: '${campaign.donorCount} hiệp sĩ',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: DonationPalette.primary),
                          ),
                          const TextSpan(text: ' đã cùng bạn viết tiếp câu chuyện này.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required double current,
    required double target,
    required double progress,
    required bool isCash,
    required DonationCampaign campaign,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat('#,###');
    final currentText = isCash ? '${formatter.format(current)} VND' : '${current.toInt()} điểm';
    final targetText = isCash ? '${formatter.format(target)} VND' : '${target.toInt()} điểm';
    final percent = (progress * 100).toInt();

    // Quy đổi phần đã góp sang tác động cụ thể để con số trở nên "chạm được".
    String? impactLine;
    if (campaign.hasImpactUnit) {
      final units = isCash
          ? campaign.impactUnitsForAmount(current)
          : campaign.impactUnitsForPoints(current.toInt());
      if (units > 0) {
        impactLine = 'Tương đương $units ${campaign.impactUnit} đã được trao đi';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: DonationPalette.strongText(isDark),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: DonationPalette.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress == 0 ? null : progress,
            backgroundColor: DonationPalette.primary.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(DonationPalette.primary),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đã góp: $currentText',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DonationPalette.strongText(isDark)),
            ),
            Text('Đích đến: $targetText', style: TextStyle(fontSize: 12, color: DonationPalette.mutedText(isDark))),
          ],
        ),
        if (impactLine != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.eco_rounded, size: 13, color: DonationPalette.amber),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  impactLine,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: DonationPalette.mutedText(isDark),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAboutTab(DonationCampaign campaign, bool isDark) {
    final beneficiary = (campaign.beneficiaryName ?? '').trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Câu chuyện người thụ hưởng — chất liệu thấu cảm chính.
          if (campaign.hasStory) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DonationPalette.coral.withOpacity(isDark ? 0.16 : 0.08),
                    DonationPalette.primary.withOpacity(isDark ? 0.12 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: DonationPalette.primary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DonationPalette.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_stories_rounded, size: 18, color: DonationPalette.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Câu chuyện',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: DonationPalette.mutedText(isDark),
                              ),
                            ),
                            if (beneficiary.isNotEmpty)
                              Text(
                                beneficiary,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: DonationPalette.strongText(isDark),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    campaign.beneficiaryStory!.trim(),
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.7,
                      color: DonationPalette.strongText(isDark).withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Về dự án',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: DonationPalette.strongText(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            campaign.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: DonationPalette.mutedText(isDark),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(bool isDark) {
    if (_leaderboard.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border_rounded, size: 48, color: DonationPalette.primary.withOpacity(0.6)),
              const SizedBox(height: 12),
              Text(
                'Chưa có ai đồng hành.\nHãy là người đầu tiên gieo hy vọng!',
                textAlign: TextAlign.center,
                style: TextStyle(color: DonationPalette.mutedText(isDark), fontSize: 13.5, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaderboard.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Những tấm lòng đã chung tay',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: DonationPalette.mutedText(isDark),
              ),
            ),
          );
        }

        final donor = _leaderboard[index - 1];
        final rank = index - 1;
        return _buildDonorTile(donor, rank, isDark);
      },
    );
  }

  Widget _buildDonorTile(CampaignDonation donor, int index, bool isDark) {
    final isTop3 = index < 3;
    Color? medalColor;
    if (index == 0) medalColor = DonationPalette.gold;
    if (index == 1) medalColor = DonationPalette.silver;
    if (index == 2) medalColor = DonationPalette.bronze;

    final amountText = donor.amount > 0
        ? '${NumberFormat('#,###').format(donor.amount)}đ'
        : '${donor.points} điểm Hero';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DonationPalette.surface(isDark).withOpacity(isDark ? 0.5 : 1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop3 ? medalColor!.withOpacity(0.4) : DonationPalette.subtleBorder(isDark),
          width: isTop3 ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar tròn với chữ cái đầu + huy hiệu hạng
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: donor.isAnonymous
                          ? null
                          : DonationPalette.warmGradient,
                      color: donor.isAnonymous ? DonationPalette.primary.withOpacity(0.12) : null,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        donor.initial,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: donor.isAnonymous ? DonationPalette.primary : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (isTop3)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: medalColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: DonationPalette.surface(isDark), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donor.donorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: DonationPalette.strongText(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đã trao $amountText',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: DonationPalette.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (donor.lastDonatedAt != null)
                Text(
                  DateFormat('dd/MM').format(donor.lastDonatedAt!.toLocal()),
                  style: TextStyle(fontSize: 11, color: DonationPalette.mutedText(isDark)),
                ),
            ],
          ),
          // Lời chúc dạng bong bóng — chất liệu thấu cảm chính của bảng vàng.
          if (donor.hasMessage) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: DonationPalette.amber.withOpacity(isDark ? 0.14 : 0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote_rounded, size: 16, color: DonationPalette.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      donor.message!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        fontStyle: FontStyle.italic,
                        color: DonationPalette.strongText(isDark).withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(DonationCampaign campaign) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: DonationPalette.surface(isDark),
        border: Border(top: BorderSide(color: DonationPalette.subtleBorder(isDark))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: DonationPalette.warmGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: DonationPalette.primary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showDonationBottomSheet(campaign),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.favorite_rounded, size: 20),
              label: const Text(
                'Gửi yêu thương',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDonationBottomSheet(DonationCampaign campaign) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DonationFormBottomSheet(
        controller: widget.controller,
        campaign: campaign,
        onSuccess: (result) {
          Navigator.of(context).pop(); // Đóng bottom sheet
          _loadDetails(showLoading: false); // Làm mới ngầm
          // Khoảnh khắc cảm ơn full-screen thay cho SnackBar lạnh lẽo.
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DonationThankYouScreen(
                campaign: campaign,
                result: result,
                onViewLeaderboard: () {
                  _tabController.animateTo(1);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DonationFormBottomSheet extends StatefulWidget {
  const _DonationFormBottomSheet({
    required this.controller,
    required this.campaign,
    required this.onSuccess,
  });

  final PulseLinkController controller;
  final DonationCampaign campaign;
  final ValueChanged<DonationResult> onSuccess;

  @override
  State<_DonationFormBottomSheet> createState() => _DonationFormBottomSheetState();
}

class _DonationFormBottomSheetState extends State<_DonationFormBottomSheet> {
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  
  // Tab type index: 0 = Cash, 1 = Points (Hero Points)
  int _selectedTypeIndex = 0;
  
  // Presets
  final List<double> _cashPresets = [50000, 100000, 200000, 500000];
  final List<int> _pointsPresets = [50, 100, 200, 500];

  double _selectedCashAmount = 100000;
  int _selectedPointsAmount = 100;
  String _selectedPaymentMethod = 'momo';
  bool _isAnonymous = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Default form name is current user name
    final user = widget.controller.state.profile;
    _nameController.text = user?.name ?? '';
    
    // Choose index based on campaign type availability
    if (widget.campaign.type == 'points') {
      _selectedTypeIndex = 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  DonationResult _buildResult({required bool isPending}) {
    return DonationResult(
      isCash: _selectedTypeIndex == 0,
      amount: _selectedTypeIndex == 0 ? _selectedCashAmount : 0,
      points: _selectedTypeIndex == 0 ? 0 : _selectedPointsAmount,
      donorName: _nameController.text.trim(),
      message: _messageController.text.trim(),
      isAnonymous: _isAnonymous,
      isPending: isPending,
    );
  }

  Future<void> _submitDonation() async {
    setState(() => _submitting = true);
    try {
      if (_selectedTypeIndex == 0) {
        // Cash donation
        final res = await widget.controller.donationFundService.donateCash(
          campaignId: widget.campaign.id,
          amount: _selectedCashAmount,
          paymentMethod: _selectedPaymentMethod,
          donorName: _nameController.text,
          message: _messageController.text,
          isAnonymous: _isAnonymous,
        );

        final paymentUrl = res['payment_url'] as String?;
        if (paymentUrl != null) {
          final uri = Uri.parse(paymentUrl);
          if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            // Tiền mặt: webhook xác nhận sau nên đánh dấu pending.
            widget.onSuccess(_buildResult(isPending: true));
          } else {
            throw 'Không thể khởi động cổng thanh toán.';
          }
        }
      } else {
        // Points donation
        await widget.controller.donationFundService.donatePoints(
          campaignId: widget.campaign.id,
          points: _selectedPointsAmount,
          donorName: _nameController.text,
          message: _messageController.text,
          isAnonymous: _isAnonymous,
        );
        widget.onSuccess(_buildResult(isPending: false));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('không đủ')
                ? 'Số dư điểm Hero không đủ để thực hiện quyên góp.'
                : 'Đã xảy ra lỗi khi thực hiện quyên góp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = widget.controller.state.profile;
    final userPoints = profile?.points ?? 0;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Gửi yêu thương',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: DonationPalette.strongText(isDark),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mỗi đóng góp, dù nhỏ, đều tạo nên khác biệt.',
                style: TextStyle(fontSize: 13, color: DonationPalette.mutedText(isDark)),
              ),
              const SizedBox(height: 16),

              // Tabs if campaign allows both
              if (widget.campaign.type == 'both') ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(0, 'Tiền mặt', Icons.favorite_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeButton(1, 'Điểm Hero', Icons.stars_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Content based on index
              if (_selectedTypeIndex == 0) ...[
                Text(
                  'Chọn số tiền ủng hộ',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: DonationPalette.strongText(isDark)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _cashPresets.map((amount) {
                    final isSel = _selectedCashAmount == amount;
                    return _buildAmountChip(
                      selected: isSel,
                      label: '${NumberFormat('#,###').format(amount)}đ',
                      hint: _impactHint(isCash: true, value: amount),
                      isDark: isDark,
                      onTap: () => setState(() => _selectedCashAmount = amount),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cổng thanh toán',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: DonationPalette.strongText(isDark)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPaymentMethodTile('momo', 'Ví MoMo'),
                    const SizedBox(width: 12),
                    _buildPaymentMethodTile('vnpay', 'VNPay'),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chọn số điểm ủng hộ',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: DonationPalette.strongText(isDark)),
                    ),
                    Text(
                      'Số dư: $userPoints điểm',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DonationPalette.mutedText(isDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _pointsPresets.map((points) {
                    final isSel = _selectedPointsAmount == points;
                    return _buildAmountChip(
                      selected: isSel,
                      label: '$points điểm',
                      hint: _impactHint(isCash: false, value: points.toDouble()),
                      isDark: isDark,
                      onTap: () => setState(() => _selectedPointsAmount = points),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),
              
              // Form details
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Quyên góp ẩn danh (Giấu tên trên bảng vàng)', style: TextStyle(fontSize: 13)),
                value: _isAnonymous,
                activeColor: const Color(0xFFE31837),
                onChanged: (val) => setState(() => _isAnonymous = val ?? false),
              ),
              
              if (!_isAnonymous) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên hiệp sĩ',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              TextField(
                controller: _messageController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Gửi một lời chúc (không bắt buộc)',
                  hintText: 'Lời nhắn của bạn sẽ xuất hiện trên bảng vàng tri ân',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 24),

              // Button action
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _submitting ? null : DonationPalette.warmGradient,
                    color: _submitting ? Colors.grey.withOpacity(0.3) : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submitDonation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _submitting
                        ? const SizedBox.shrink()
                        : const Icon(Icons.favorite_rounded, size: 20),
                    label: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            _selectedTypeIndex == 0 ? 'Tiến hành gửi tặng' : 'Xác nhận tặng điểm',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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

  /// Gợi ý quy đổi tác động cho một mức đóng góp, ví dụ "≈ 2 phần cơm".
  String? _impactHint({required bool isCash, required double value}) {
    final c = widget.campaign;
    if (!c.hasImpactUnit) return null;
    final units = isCash
        ? c.impactUnitsForAmount(value)
        : c.impactUnitsForPoints(value.toInt());
    if (units <= 0) return null;
    return '≈ $units ${c.impactUnit}';
  }

  Widget _buildAmountChip({
    required bool selected,
    required String label,
    required String? hint,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? DonationPalette.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? DonationPalette.primary : DonationPalette.subtleBorder(isDark),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: selected ? DonationPalette.primary : DonationPalette.strongText(isDark),
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 2),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? DonationPalette.primary.withOpacity(0.8) : DonationPalette.mutedText(isDark),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(int index, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSel = _selectedTypeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTypeIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? DonationPalette.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? DonationPalette.primary : DonationPalette.subtleBorder(isDark),
            width: isSel ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSel ? DonationPalette.primary : DonationPalette.mutedText(isDark)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSel ? DonationPalette.primary : DonationPalette.mutedText(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(String method, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSel = _selectedPaymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSel ? DonationPalette.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? DonationPalette.primary : DonationPalette.subtleBorder(isDark),
              width: isSel ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSel ? DonationPalette.primary : DonationPalette.mutedText(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
