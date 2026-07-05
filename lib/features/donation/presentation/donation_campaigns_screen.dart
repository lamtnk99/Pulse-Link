import 'package:flutter/material.dart';
import '../../../core/theme/pulse_link_theme.dart';
import '../domain/donation_campaign.dart';
import '../../../app/pulse_link_controller.dart';
import 'donation_detail_screen.dart';

class DonationCampaignsScreen extends StatefulWidget {
  const DonationCampaignsScreen({
    super.key,
    required this.controller,
  });

  final PulseLinkController controller;

  @override
  State<DonationCampaignsScreen> createState() => _DonationCampaignsScreenState();
}

class _DonationCampaignsScreenState extends State<DonationCampaignsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<DonationCampaign> _campaigns = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCampaigns();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'ĐỒNG HÀNH QUYÊN GÓP',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE31837),
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorColor: const Color(0xFFE31837),
          indicatorWeight: 3.0,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'QUYÊN GÓP TÀI CHÍNH', icon: Icon(Icons.wallet)),
            Tab(text: 'QUYÊN GÓP ĐIỂM HERO', icon: Icon(Icons.stars)),
          ],
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
        child: CircularProgressIndicator(color: Color(0xFFE31837)),
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
                  const Icon(Icons.error_outline, size: 64, color: Color(0xFFE31837)),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCampaigns,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31837),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('TẢI LẠI'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildCampaignList(
          _campaigns.where((c) => c.isFinancial).toList(),
          isFinancial: true,
          isDark: isDark,
        ),
        _buildCampaignList(
          _campaigns.where((c) => c.isPoints).toList(),
          isFinancial: false,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildCampaignList(List<DonationCampaign> list, {required bool isFinancial, required bool isDark}) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const Center(
            child: Text(
              'Chưa có chiến dịch quyên góp nào đang diễn ra.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
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
        return _buildCampaignCard(campaign, isFinancial, isDark);
      },
    );
  }

  Widget _buildCampaignCard(DonationCampaign campaign, bool isFinancial, bool isDark) {
    final progress = isFinancial ? campaign.financialProgress : campaign.pointsProgress;
    final progressPercent = (progress * 100).toInt();

    final targetText = isFinancial
        ? '${_formatCurrency(campaign.targetAmount)}đ'
        : '${campaign.targetPoints} điểm';
    final raisedText = isFinancial
        ? '${_formatCurrency(campaign.currentAmount)}đ'
        : '${campaign.currentPoints} điểm';

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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: campaign.imageUrl != null
                    ? Image.network(
                        campaign.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    campaign.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    campaign.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiến độ: $progressPercent%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE31837),
                        ),
                      ),
                      Text(
                        'Mục tiêu: $targetText',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE31837)),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Raised Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã quyên góp: $raisedText',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white38 : Colors.black38,
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
    return Container(
      color: Colors.red.withOpacity(0.1),
      child: const Center(
        child: Icon(Icons.favorite, color: Color(0xFFE31837), size: 48),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} Tr';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
