import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/pulse_link_controller.dart';
import '../../../core/theme/pulse_link_theme.dart';
import '../../../core/utils/vietnamese_labels.dart';
import '../../community/domain/community_post.dart';
import '../../community/presentation/community_post_card.dart';
import '../../community/presentation/community_post_detail_screen.dart';
import '../domain/donation_appointment.dart';
import '../domain/donation_event.dart';
import '../domain/past_donation.dart';
import 'donation_event_detail_screen.dart';
import 'widgets/donation_event_card.dart';
import 'widgets/donation_history_tile.dart';
import 'widgets/event_map_preview.dart';
import 'widgets/health_tracker_card.dart';
import 'widgets/hero_pass_card.dart';

class DailyModeScreen extends StatefulWidget {
  const DailyModeScreen({
    super.key,
    required this.controller,
  });

  final PulseLinkController controller;

  @override
  State<DailyModeScreen> createState() => _DailyModeScreenState();
}

class _DailyModeScreenState extends State<DailyModeScreen> {
  int _currentIndex = 0;
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        final profile = state.profile;

        if (state.isLoading || profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final pages = [
          _HomeTab(
            controller: widget.controller,
            showMap: _showMap,
            onToggleMap: () => setState(() => _showMap = !_showMap),
          ),
          _EventsTab(
            controller: widget.controller,
            showMap: _showMap,
            onToggleMap: () => setState(() => _showMap = !_showMap),
          ),
          _BookingsTab(controller: widget.controller),
          _HistoryTab(controller: widget.controller),
          _ProfileTab(controller: widget.controller),
        ];

        return Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            backgroundColor: PulseLinkTheme.cardBackground,
            indicatorColor: PulseLinkTheme.primaryRed.withOpacity(0.18),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map_rounded),
                label: 'Sự kiện',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_available_outlined),
                selectedIcon: Icon(Icons.event_available_rounded),
                label: 'Lịch đặt',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'Lịch sử',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Hồ sơ',
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _openEventDetail(
  BuildContext context,
  PulseLinkController controller,
  DonationEvent event,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DonationEventDetailScreen(
        controller: controller,
        initialEvent: event,
      ),
    ),
  );
}

Future<void> _openPostDetail(
  BuildContext context,
  PulseLinkController controller,
  CommunityPost post,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CommunityPostDetailScreen(
        controller: controller,
        initialPost: post,
      ),
    ),
  );
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.controller,
    required this.showMap,
    required this.onToggleMap,
  });

  final PulseLinkController controller;
  final bool showMap;
  final VoidCallback onToggleMap;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final profile = state.profile!;
    final now = DateTime.now();
    final events = state.events.take(3).toList(growable: false);
    final posts = state.communityPosts.take(3).toList(growable: false);

    return RefreshIndicator(
      onRefresh: controller.refreshDailyData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _DailyHeader(controller: controller),
          const SizedBox(height: 18),
          HeroPassCard(
            profile: profile,
            totalVolumeMl: state.totalVolumeMl,
          ),
          const SizedBox(height: 16),
          HealthTrackerCard(
            daysLeft: profile.daysUntilEligible(now),
            progress: profile.recoveryProgress(now),
            nextEligibleDate: profile.nextEligibleDate,
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Sự kiện hiến máu',
            actionLabel: showMap ? 'Danh sách' : 'Bản đồ',
            onAction: onToggleMap,
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: showMap
                ? EventMapPreview(
                    key: const ValueKey('home-map'),
                    events: events,
                  )
                : SizedBox(
                    key: const ValueKey('home-list'),
                    height: 272,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 286,
                          child: DonationEventCard(
                            event: events[index],
                            onOpenDetails: () => _openEventDetail(
                              context,
                              controller,
                              events[index],
                            ),
                            onBookingToggle: () => _toggleBooking(
                              context,
                              events[index],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemCount: events.length,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Tin cộng đồng',
          ),
          const SizedBox(height: 12),
          if (posts.isEmpty)
            const _EmptyState(
              icon: Icons.article_outlined,
              title: 'Chưa có bài viết mới',
              subtitle: 'Các cập nhật từ bệnh viện sẽ hiển thị tại đây.',
            )
          else
            for (final post in posts) ...[
              CommunityPostCard(
                post: post,
                onTap: () => _openPostDetail(context, controller, post),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Future<void> _toggleBooking(
    BuildContext context,
    DonationEvent event,
  ) async {
    await controller.toggleBooking(event);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          event.booked
              ? 'Đã hủy lịch hiến.'
              : 'Đặt lịch hiến máu thành công.',
        ),
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({
    required this.controller,
    required this.showMap,
    required this.onToggleMap,
  });

  final PulseLinkController controller;
  final bool showMap;
  final VoidCallback onToggleMap;

  @override
  Widget build(BuildContext context) {
    final events = controller.state.events;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _ScreenTitle(
          title: 'Sự kiện gần bạn',
          subtitle: 'Danh sách hiến máu được đồng bộ từ hệ thống.',
          trailing: IconButton.filledTonal(
            onPressed: onToggleMap,
            icon: Icon(showMap ? Icons.view_agenda_outlined : Icons.map),
            tooltip: showMap ? 'Hiện danh sách' : 'Hiện bản đồ',
          ),
        ),
        const SizedBox(height: 12),
        if (showMap) ...[
          EventMapPreview(events: events),
          const SizedBox(height: 14),
        ],
        for (final event in events) ...[
          DonationEventCard(
            event: event,
            expanded: true,
            onOpenDetails: () => _openEventDetail(
              context,
              controller,
              event,
            ),
            onBookingToggle: () async {
              await controller.toggleBooking(event);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    event.booked
                        ? 'Đã hủy lịch hiến.'
                        : 'Đặt lịch hiến máu thành công.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BookingsTab extends StatelessWidget {
  const _BookingsTab({
    required this.controller,
  });

  final PulseLinkController controller;

  @override
  Widget build(BuildContext context) {
    final appointments = controller.state.bookedAppointments;

    return RefreshIndicator(
      onRefresh: controller.refreshDailyData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _ScreenTitle(
            title: 'Lịch đã đặt',
            subtitle: appointments.isEmpty
                ? 'Bạn chưa có lịch hiến máu sắp tới.'
                : '${appointments.length} lịch hẹn đang chờ tham gia.',
          ),
          const SizedBox(height: 12),
          if (appointments.isEmpty)
            const _EmptyState(
              icon: Icons.event_available_outlined,
              title: 'Chưa có lịch đặt',
              subtitle: 'Hãy chọn một sự kiện gần bạn và đặt lịch trước.',
            )
          else
            for (final appointment in appointments) ...[
              _AppointmentCard(
                appointment: appointment,
                onOpenDetails: () => _openEventDetail(
                  context,
                  controller,
                  appointment.event,
                ),
                onCancel: () async {
                  await controller.toggleBooking(appointment.event);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã hủy lịch hiến.')),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.controller,
  });

  final PulseLinkController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final history = state.donationHistory;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _ScreenTitle(
          title: 'Lịch sử hiến máu',
          subtitle: '${state.totalVolumeMl} ml máu đã đóng góp.',
          trailing: IconButton.filled(
            onPressed: () => _showAddDonationSheet(context),
            icon: const Icon(Icons.add),
            tooltip: 'Thêm lần hiến máu',
          ),
        ),
        const SizedBox(height: 12),
        for (final donation in history) ...[
          DonationHistoryTile(donation: donation),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Future<void> _showAddDonationSheet(BuildContext context) async {
    final draft = await showModalBottomSheet<PastDonationDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _DonationDraftSheet(
          bloodType: controller.state.profile!.bloodType,
        );
      },
    );

    if (draft == null) return;
    await controller.logDonation(draft);
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.controller,
  });

  final PulseLinkController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final profile = state.profile!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _ScreenTitle(
          title: 'Hồ sơ hiệp sĩ',
          subtitle: 'Thông tin cá nhân, nhóm máu và trạng thái hồi phục.',
          trailing: IconButton.filledTonal(
            onPressed: controller.simulateSosAlert,
            icon: const Icon(Icons.sos),
            tooltip: 'Mô phỏng SOS',
          ),
        ),
        const SizedBox(height: 16),
        HeroPassCard(
          profile: profile,
          totalVolumeMl: state.totalVolumeMl,
        ),
        const SizedBox(height: 16),
        _ProfileMetricRow(
          label: 'Cấp độ cống hiến',
          value: VietnameseLabels.heroLevel(profile.heroLevel),
          icon: Icons.workspace_premium_outlined,
        ),
        _ProfileMetricRow(
          label: 'Điểm tích lũy',
          value: NumberFormat.decimalPattern().format(profile.points),
          icon: Icons.bolt_outlined,
        ),
        _ProfileMetricRow(
          label: 'Mã tỉnh/thành',
          value: profile.provinceCode,
          icon: Icons.location_city_outlined,
        ),
        _ProfileMetricRow(
          label: 'Mã Hero Pass',
          value: profile.heroPassCode,
          icon: Icons.qr_code_2_outlined,
        ),
      ],
    );
  }
}

class _DailyHeader extends StatelessWidget {
  const _DailyHeader({
    required this.controller,
  });

  final PulseLinkController controller;

  @override
  Widget build(BuildContext context) {
    final profile = controller.state.profile!;

    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: PulseLinkTheme.cardBackground,
          child: Icon(Icons.favorite, color: PulseLinkTheme.primaryRed),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào, hiệp sĩ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PulseLinkTheme.mutedText,
                    ),
              ),
              Text(
                profile.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: controller.simulateSosAlert,
          icon: const Icon(Icons.notifications_active_outlined),
          tooltip: 'Mô phỏng tín hiệu SOS',
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.swap_horiz),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onOpenDetails,
    required this.onCancel,
  });

  final DonationAppointment appointment;
  final VoidCallback onOpenDetails;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final event = appointment.event;

    return Container(
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onOpenDetails,
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            leading: const CircleAvatar(
              backgroundColor: Colors.white10,
              child: Icon(
                Icons.event_available_outlined,
                color: PulseLinkTheme.successGreen,
              ),
            ),
            title: Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${DateFormat('dd/MM/yyyy - HH:mm').format(event.startsAt)}\n${event.locationName}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PulseLinkTheme.mutedText,
                  height: 1.35,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    appointment.bookedAt == null
                        ? 'Đã xác nhận lịch'
                        : 'Đặt lúc ${DateFormat('dd/MM/yyyy - HH:mm').format(appointment.bookedAt!)}',
                    style: const TextStyle(
                      color: PulseLinkTheme.successGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Hủy lịch'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: PulseLinkTheme.primaryRed, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: PulseLinkTheme.mutedText),
          ),
        ],
      ),
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PulseLinkTheme.mutedText,
                    ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ProfileMetricRow extends StatelessWidget {
  const _ProfileMetricRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: PulseLinkTheme.primaryRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: PulseLinkTheme.mutedText),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonationDraftSheet extends StatefulWidget {
  const _DonationDraftSheet({
    required this.bloodType,
  });

  final String bloodType;

  @override
  State<_DonationDraftSheet> createState() => _DonationDraftSheetState();
}

class _DonationDraftSheetState extends State<_DonationDraftSheet> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _donatedAt = DateTime.now();
  int _volumeMl = 350;

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ghi nhận lần hiến máu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Nơi hiến máu',
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập địa điểm';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _volumeMl,
              decoration: const InputDecoration(
                labelText: 'Thể tích',
                prefixIcon: Icon(Icons.water_drop_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 250, child: Text('250 ml')),
                DropdownMenuItem(value: 350, child: Text('350 ml')),
                DropdownMenuItem(value: 450, child: Text('450 ml')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _volumeMl = value);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _donatedAt,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _donatedAt = picked);
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(DateFormat('dd/MM/yyyy').format(_donatedAt)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú sức khỏe',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.of(context).pop(
                  PastDonationDraft(
                    donatedAt: _donatedAt,
                    locationName: _locationController.text.trim(),
                    volumeMl: _volumeMl,
                    bloodType: widget.bloodType,
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Xác nhận lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
