import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/pulse_link_theme.dart';
import '../../../app/pulse_link_controller.dart';
import '../domain/donation_campaign.dart';
import '../domain/campaign_donation.dart';

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
        appBar: AppBar(title: const Text('CHI TIẾT QUYÊN GÓP')),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE31837)),
        ),
      );
    }

    if (_error != null || _campaign == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('CHI TIẾT QUYÊN GÓP')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Color(0xFFE31837)),
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
              labelColor: const Color(0xFFE31837),
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
              indicatorColor: const Color(0xFFE31837),
              tabs: const [
                Tab(text: 'GIỚI THIỆU'),
                Tab(text: 'BẢNG VÀNG TRI ÂN'),
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
            campaign.title.toUpperCase(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          if (showCash) ...[
            _buildProgressRow(
              label: 'Quyên góp tài chính',
              current: campaign.currentAmount,
              target: campaign.targetAmount,
              progress: campaign.financialProgress,
              isCash: true,
            ),
            if (showPoints) const SizedBox(height: 16),
          ],
          if (showPoints)
            _buildProgressRow(
              label: 'Quyên góp điểm Hero',
              current: campaign.currentPoints.toDouble(),
              target: campaign.targetPoints.toDouble(),
              progress: campaign.pointsProgress,
              isCash: false,
            ),
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
  }) {
    final formatter = NumberFormat('#,###');
    final currentText = isCash ? '${formatter.format(current)} VND' : '${current.toInt()} Pts';
    final targetText = isCash ? '${formatter.format(target)} VND' : '${target.toInt()} Pts';
    final percent = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              '$percent%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFE31837)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.red.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE31837)),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Đã đạt: $currentText', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('Mục tiêu: $targetText', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutTab(DonationCampaign campaign, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THÔNG TIN DỰ ÁN',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            campaign.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(bool isDark) {
    if (_leaderboard.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có lượt đóng góp nào. Hãy là người đầu tiên!',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaderboard.length,
      itemBuilder: (context, index) {
        final donor = _leaderboard[index];
        final isTop3 = index < 3;
        
        Color badgeColor = Colors.transparent;
        if (index == 0) badgeColor = const Color(0xFFFFD700); // Gold
        if (index == 1) badgeColor = const Color(0xFFC0C0C0); // Silver
        if (index == 2) badgeColor = const Color(0xFFCD7F32); // Bronze

        final amountText = donor.amount > 0 
            ? '+${NumberFormat('#,###').format(donor.amount)} VND'
            : '+${donor.points} Hero Pts';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTop3 
                  ? badgeColor.withOpacity(0.3) 
                  : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03)),
              width: isTop3 ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isTop3 ? badgeColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isTop3 ? null : Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isTop3 ? Colors.black87 : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Donor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donor.donorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amountText,
                      style: const TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFE31837)
                      ),
                    ),
                  ],
                ),
              ),
              // Time
              if (donor.lastDonatedAt != null)
                Text(
                  DateFormat('dd/MM HH:mm').format(donor.lastDonatedAt!.toLocal()),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActionBar(DonationCampaign campaign) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _showDonationBottomSheet(campaign),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31837),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: const Text(
              'QUYÊN GÓP NGAY',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
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
        onSuccess: () {
          Navigator.of(context).pop(); // Close bottom sheet
          _loadDetails(showLoading: true); // Reload details
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cảm ơn đóng góp quý giá của bạn!'),
              backgroundColor: Colors.green,
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
  final VoidCallback onSuccess;

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
            // Success callback will trigger when payment is done and screen is re-polled
            widget.onSuccess();
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
        widget.onSuccess();
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
              const Text(
                'ỦNG HỘ ĐỒNG HÀNH',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
              ),
              const SizedBox(height: 16),
              
              // Tabs if campaign allows both
              if (widget.campaign.type == 'both') ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(0, 'TIỀN MẶT', Icons.wallet),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeButton(1, 'ĐIỂM HERO', Icons.stars),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Content based on index
              if (_selectedTypeIndex == 0) ...[
                // Cash limits presets
                const Text('Chọn số tiền ủng hộ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _cashPresets.map((amount) {
                    final isSel = _selectedCashAmount == amount;
                    return ChoiceChip(
                      label: Text('${NumberFormat('#,###').format(amount)}đ'),
                      selected: isSel,
                      selectedColor: const Color(0xFFE31837).withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: isSel ? const Color(0xFFE31837) : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _selectedCashAmount = amount),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Payment Methods
                const Text('Cổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPaymentMethodTile('momo', 'Ví MoMo'),
                    const SizedBox(width: 12),
                    _buildPaymentMethodTile('vnpay', 'VNPay'),
                  ],
                ),
              ] else ...[
                // Points limit presets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Chọn số điểm ủng hộ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      'Số dư: $userPoints Pts',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _pointsPresets.map((points) {
                    final isSel = _selectedPointsAmount == points;
                    return ChoiceChip(
                      label: Text('$points Pts'),
                      selected: isSel,
                      selectedColor: const Color(0xFFE31837).withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: isSel ? const Color(0xFFE31837) : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _selectedPointsAmount = points),
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
                decoration: const InputDecoration(
                  labelText: 'Lời chúc gửi tới chiến dịch (Không bắt buộc)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 24),

              // Button action
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31837),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _selectedTypeIndex == 0 ? 'TIẾN HÀNH THANH TOÁN' : 'XÁC NHẬN ỦNG HỘ ĐIỂM',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(int index, String label, IconData icon) {
    final isSel = _selectedTypeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTypeIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFE31837).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? const Color(0xFFE31837) : Colors.grey.withOpacity(0.3),
            width: isSel ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSel ? const Color(0xFFE31837) : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSel ? const Color(0xFFE31837) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(String method, String label) {
    final isSel = _selectedPaymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFFE31837).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? const Color(0xFFE31837) : Colors.grey.withOpacity(0.3),
              width: isSel ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSel ? const Color(0xFFE31837) : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
