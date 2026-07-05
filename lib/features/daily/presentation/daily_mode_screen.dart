import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/pulse_link_controller.dart';
import '../../../core/enums/app_theme_preference.dart';
import '../../../core/theme/pulse_link_theme.dart';
import '../../../core/utils/vietnamese_labels.dart';
import '../../community/domain/community_post.dart';
import '../../community/presentation/community_post_card.dart';
import '../../community/presentation/community_post_detail_screen.dart';
import '../../profile/domain/donor_profile.dart';
import '../domain/donation_appointment.dart';
import '../domain/donation_event.dart';
import '../domain/past_donation.dart';
import 'donation_event_detail_screen.dart';
import 'donation_events_map_screen.dart';
import 'utils/map_launcher.dart';
import 'widgets/donation_event_card.dart';
import 'widgets/donation_history_tile.dart';
import 'widgets/event_map_preview.dart';
import 'widgets/hero_pass_card.dart';
import '../../chat/presentation/draggable_chat_fab.dart';
import '../../donation/domain/donation_campaign.dart';
import '../../donation/presentation/donation_campaigns_screen.dart';
import '../../donation/presentation/donation_detail_screen.dart';
import '../../donation/presentation/donation_palette.dart';

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

        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (profile == null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 44,
                      color: PulseLinkTheme.primaryRed,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Chưa tải được dữ liệu người hiến',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.initializationError ??
                          'Kiểm tra Laravel API và dữ liệu seed rồi thử lại.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: PulseLinkTheme.mutedText,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: widget.controller.initialize,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
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

        return Stack(
          children: [
            Scaffold(
              body: SafeArea(
                child: IndexedStack(
                  index: _currentIndex,
                  children: pages,
                ),
              ),
              bottomNavigationBar: _PulseBottomNavBar(
                currentIndex: _currentIndex,
                onSelected: (index) {
                  setState(() => _currentIndex = index);
                },
              ),
            ),
            DraggableChatFab(controller: widget.controller),
          ],
        );
      },
    );
  }
}

class _PulseBottomNavBar extends StatelessWidget {
  const _PulseBottomNavBar({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _PulseNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Trang chủ',
    ),
    _PulseNavItem(
      icon: Icons.map_outlined,
      selectedIcon: Icons.map_rounded,
      label: 'Sự kiện',
    ),
    _PulseNavItem(
      icon: Icons.event_available_outlined,
      selectedIcon: Icons.event_available_rounded,
      label: 'Lịch',
    ),
    _PulseNavItem(
      icon: Icons.volunteer_activism_outlined,
      selectedIcon: Icons.volunteer_activism_rounded,
      label: 'Sổ hiến',
    ),
    _PulseNavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Hồ sơ',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = PulseLinkTheme.isDark(context);
    final surface = PulseLinkTheme.surfaceColor(context);
    final border = PulseLinkTheme.subtleBorderColor(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            child: Row(
              children: [
                for (var index = 0; index < _items.length; index++)
                  Expanded(
                    child: _PulseBottomNavItem(
                      item: _items[index],
                      selected: currentIndex == index,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseBottomNavItem extends StatelessWidget {
  const _PulseBottomNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _PulseNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted = PulseLinkTheme.mutedColor(context);
    final textColor = selected ? primary : muted;

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: selected ? 42 : 34,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    selected ? item.selectedIcon : item.icon,
                    color: selected ? primary : muted,
                    size: selected ? 21 : 20,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontFamilyFallback: const ['Roboto', 'Arial', 'sans-serif'],
                    color: textColor,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.1,
                    letterSpacing: 0,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseNavItem {
  const _PulseNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
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

Future<void> _openEventsMap(
  BuildContext context,
  PulseLinkController controller,
  List<DonationEvent> events,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DonationEventsMapScreen(
        controller: controller,
        events: events,
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

Future<void> _handleBookingAction(
  BuildContext context,
  PulseLinkController controller,
  DonationEvent event,
) async {
  if (event.booked) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy lịch này?'),
        content: Text(
          'Nếu hôm đó bạn chưa khỏe hoặc có việc bận, cứ hủy lịch. Bạn luôn có thể đặt lại khi sẵn sàng.\n\n${event.title}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Giữ lịch'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await controller.toggleBooking(event);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Lịch đã được hủy. Hẹn bạn khi cơ thể sẵn sàng hơn.')),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Giữ một chỗ cho bạn?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.title),
          const SizedBox(height: 12),
          const _PreparationChecklist(compact: true),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Để sau'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Đặt lịch'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  await controller.toggleBooking(event);
  if (!context.mounted) return;
  await _showBookingConfirmed(context, event);
}

Future<void> _showBookingConfirmed(
  BuildContext context,
  DonationEvent event,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Lịch đã được giữ cho bạn'),
      content: Text(
        'Bạn không cần vội. Trước ngày hiến, hãy ngủ đủ, ăn nhẹ và uống nước. Nếu thấy người không ổn, hủy lịch cũng là một lựa chọn đúng.\n\n${DateFormat('HH:mm dd/MM/yyyy').format(event.startsAt)} · ${event.locationName}',
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            openDonationEventDirections(event);
          },
          icon: const Icon(Icons.directions_outlined),
          label: const Text('Chỉ đường'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Đã rõ'),
        ),
      ],
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

    PastDonation? activeDonation;
    for (final item in state.donationHistory) {
      if (item.bloodJourney != null && item.bloodJourney!.completedAt == null) {
        activeDonation = item;
        break;
      }
    }

    return RefreshIndicator(
      onRefresh: controller.refreshDailyData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _DailyHeader(controller: controller),
          if (activeDonation != null) ...[
            const SizedBox(height: 14),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  controller.showLiveBloodJourney(
                    activeDonation!.bloodJourney!,
                    activeDonation.locationName,
                    activeDonation.bloodType,
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE31837),
                        Color(0xFFB91C1C),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE31837).withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HÀNH TRÌNH GIỢT MÁU TRỰC TIẾP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Theo dõi tiến trình giọt máu nhóm ${activeDonation.bloodType} tại ${activeDonation.locationName}',
                              style: const TextStyle(
                                color: Color(0xDEFFFFFF),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          HeroPassCard(
            profile: profile,
            totalVolumeMl: state.totalVolumeMl,
            daysLeft: profile.daysUntilEligible(now),
            recoveryProgress: profile.recoveryProgress(now),
            nextEligibleDate: profile.nextEligibleDate,
            upcomingCount: state.bookedAppointments.length,
          ),
          const SizedBox(height: 14),
          _ImpactStrip(
            donations: profile.totalDonations,
            totalVolumeMl: state.totalVolumeMl,
            points: profile.points,
          ),
          const SizedBox(height: 14),
          _DonationPromoCard(controller: controller),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Điểm hiến phù hợp',
            actionLabel: showMap ? 'Danh sách' : 'Bản đồ',
            onAction: onToggleMap,
          ),
          const SizedBox(height: 4),
          Text(
            'Chọn điểm gần bạn, vào xem kỹ thời gian và chỉ đặt khi cơ thể thật sự ổn.',
            style: TextStyle(
              color: PulseLinkTheme.mutedColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: events.isEmpty
                ? const _EmptyState(
                    key: ValueKey('home-empty-events'),
                    icon: Icons.event_busy_outlined,
                    title: 'Chưa có điểm hiến phù hợp',
                    subtitle:
                        'Khi bệnh viện mở lịch mới gần bạn, danh sách sẽ hiện ở đây.',
                  )
                : showMap
                    ? EventMapPreview(
                        key: const ValueKey('home-map'),
                        events: events,
                        onOpenDetails: (event) => _openEventDetail(
                          context,
                          controller,
                          event,
                        ),
                        onBookingToggle: (event) =>
                            _toggleBooking(context, event),
                        onOpenDirections: openDonationEventDirections,
                        onOpenFullMap: () => _openEventsMap(
                          context,
                          controller,
                          controller.state.events,
                        ),
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemCount: events.length,
                        ),
                      ),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'Tin tức',
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
    await _handleBookingAction(context, controller, event);
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
          subtitle:
              'Xem kỹ địa điểm, thời gian và chuẩn bị sức khỏe trước khi đặt.',
          trailing: IconButton.filledTonal(
            onPressed: onToggleMap,
            icon: Icon(showMap ? Icons.view_agenda_outlined : Icons.map),
            tooltip: showMap ? 'Hiện danh sách' : 'Hiện bản đồ',
          ),
        ),
        const SizedBox(height: 12),
        if (showMap) ...[
          EventMapPreview(
            events: events,
            onOpenDetails: (event) => _openEventDetail(
              context,
              controller,
              event,
            ),
            onBookingToggle: (event) async {
              await _handleBookingAction(context, controller, event);
            },
            onOpenDirections: openDonationEventDirections,
            onOpenFullMap: () => _openEventsMap(
              context,
              controller,
              events,
            ),
          ),
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
              await _handleBookingAction(context, controller, event);
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
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Hủy lịch hiến máu?'),
                      content: Text(
                          'Bạn muốn hủy lịch "${appointment.event.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Giữ lịch'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Hủy lịch'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
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
    final profile = state.profile!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _ScreenTitle(
          title: 'Sổ hiến máu',
          subtitle: 'Chứng chỉ, thành tích và kết quả sau mỗi lần hiến.',
        ),
        const SizedBox(height: 12),
        _RecognitionSummaryCard(
          profile: profile,
          history: history,
          fallbackTotalVolumeMl: state.totalVolumeMl,
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          const _EmptyHistoryCard()
        else ...[
          _HistoryTimelineIntro(history: history),
          const SizedBox(height: 12),
          for (final donation in history) ...[
            DonationHistoryTile(donation: donation),
            const SizedBox(height: 10),
          ],
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

class _HistoryTimelineIntro extends StatelessWidget {
  const _HistoryTimelineIntro({
    required this.history,
  });

  final List<PastDonation> history;

  @override
  Widget build(BuildContext context) {
    final latest = history.first;
    final sosCount = history
        .where((donation) => donation.donationType == DonationType.sos)
        .length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseLinkTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PulseLinkTheme.subtleBorderColor(context)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timeline_outlined, color: PulseLinkTheme.primaryRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sosCount > 0
                  ? 'Sổ này có ${history.length} dấu mốc, trong đó có $sosCount lần bạn có mặt cho một ca khẩn cấp.'
                  : 'Sổ này đang giữ ${history.length} dấu mốc. Lần gần nhất là ${DateFormat('dd/MM/yyyy').format(latest.donatedAt)}.',
              style: TextStyle(
                color: PulseLinkTheme.mutedColor(context),
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecognitionSummaryCard extends StatelessWidget {
  const _RecognitionSummaryCard({
    required this.profile,
    required this.history,
    required this.fallbackTotalVolumeMl,
  });

  final DonorProfile profile;
  final List<PastDonation> history;
  final int fallbackTotalVolumeMl;

  @override
  Widget build(BuildContext context) {
    final recognition = profile.recognition;
    final totalVolumeMl = recognition.totalVolumeMl > 0
        ? recognition.totalVolumeMl
        : fallbackTotalVolumeMl;
    final sosCount = recognition.sosDonations > 0
        ? recognition.sosDonations
        : history
            .where((donation) => donation.donationType == DonationType.sos)
            .length;
    final badges = recognition.badges.isEmpty
        ? _fallbackBadges(history.length, sosCount, totalVolumeMl)
        : recognition.badges;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PulseLinkTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PulseLinkTheme.subtleBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: PulseLinkTheme.primaryRed.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.military_tech_outlined,
                  color: PulseLinkTheme.primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recognition.level.isEmpty
                          ? VietnameseLabels.heroLevel(profile.heroLevel)
                          : VietnameseLabels.text(recognition.level),
                      style: TextStyle(
                        color: PulseLinkTheme.textColor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      recognition.badgeTitle.isEmpty
                          ? VietnameseLabels.text(profile.badgeTitle)
                          : VietnameseLabels.text(recognition.badgeTitle),
                      style: TextStyle(
                        color: PulseLinkTheme.mutedColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _RecognitionMetric(
                  label: 'Tổng ml',
                  value: NumberFormat.decimalPattern().format(totalVolumeMl),
                  color: PulseLinkTheme.primaryRed,
                ),
              ),
              Expanded(
                child: _RecognitionMetric(
                  label: 'Điểm',
                  value: NumberFormat.decimalPattern().format(profile.points),
                  color: Colors.amber,
                ),
              ),
              Expanded(
                child: _RecognitionMetric(
                  label: 'SOS',
                  value: '$sosCount',
                  color: PulseLinkTheme.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RankPill(
                  icon: Icons.public_outlined,
                  label: recognition.globalRank <= 0
                      ? 'Chưa xếp hạng'
                      : 'Hạng #${recognition.globalRank} toàn hệ thống',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RankPill(
                  icon: Icons.location_city_outlined,
                  label: recognition.provinceRank <= 0
                      ? 'Theo tỉnh/thành'
                      : 'Hạng #${recognition.provinceRank} địa phương',
                ),
              ),
            ],
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final badge in badges)
                  Tooltip(
                    message: VietnameseLabels.text(badge.description),
                    child: Chip(
                      avatar: const Icon(Icons.verified_rounded, size: 16),
                      label: Text(VietnameseLabels.text(badge.name)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<DonorBadge> _fallbackBadges(
    int donations,
    int sosCount,
    int totalVolumeMl,
  ) {
    return [
      if (donations >= 1)
        const DonorBadge(
          code: 'first_donation',
          name: 'Lần hiến đầu',
          description: 'Đã có chứng nhận hiến máu đầu tiên.',
        ),
      if (donations >= 5)
        const DonorBadge(
          code: 'five_donations',
          name: '5 lần hiến',
          description: 'Duy trì thói quen hiến máu an toàn.',
        ),
      if (sosCount >= 1)
        const DonorBadge(
          code: 'sos_responder',
          name: 'SOS Responder',
          description: 'Đã hoàn thành một ca hiến máu khẩn cấp.',
        ),
      if (totalVolumeMl >= 2000)
        const DonorBadge(
          code: 'two_liters',
          name: '2.000 ml sẻ chia',
          description: 'Tổng lượng máu hiến đã vượt 2.000 ml.',
        ),
    ];
  }
}

class _RecognitionMetric extends StatelessWidget {
  const _RecognitionMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: PulseLinkTheme.mutedColor(context),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _RankPill extends StatelessWidget {
  const _RankPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: PulseLinkTheme.isDark(context)
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: PulseLinkTheme.mutedColor(context), size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: PulseLinkTheme.mutedColor(context),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PulseLinkTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PulseLinkTheme.subtleBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.menu_book_outlined,
              color: PulseLinkTheme.primaryRed),
          const SizedBox(height: 10),
          Text(
            'Sổ hiến máu đang chờ chứng chỉ đầu tiên',
            style: TextStyle(
              color: PulseLinkTheme.textColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Khi một lần hiến được xác nhận, chứng chỉ và QR verify sẽ xuất hiện tại đây.',
            style: TextStyle(
              color: PulseLinkTheme.mutedColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
        _ThemePreferenceCard(controller: controller),
        const SizedBox(height: 16),
        HeroPassCard(
          profile: profile,
          totalVolumeMl: state.totalVolumeMl,
        ),
        const SizedBox(height: 16),
        _RecognitionSummaryCard(
          profile: profile,
          history: state.donationHistory,
          fallbackTotalVolumeMl: state.totalVolumeMl,
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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton.icon(
            onPressed: () => controller.logout(),
            style: TextButton.styleFrom(
              foregroundColor: PulseLinkTheme.primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: PulseLinkTheme.primaryRed.withOpacity(0.3),
                  width: 1.4,
                ),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'ĐĂNG XUẤT',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemePreferenceCard extends StatelessWidget {
  const _ThemePreferenceCard({
    required this.controller,
  });

  final PulseLinkController controller;

  @override
  Widget build(BuildContext context) {
    final selected = controller.state.themePreference;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseLinkTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PulseLinkTheme.subtleBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: PulseLinkTheme.primaryRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.contrast_outlined,
                  color: PulseLinkTheme.primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giao diện',
                      style: TextStyle(
                        color: PulseLinkTheme.textColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đổi nền sáng/tối cho dễ nhìn hơn.',
                      style: TextStyle(
                        color: PulseLinkTheme.mutedColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<AppThemePreference>(
            showSelectedIcon: false,
            segments: [
              for (final preference in AppThemePreference.values)
                ButtonSegment(
                  value: preference,
                  icon: Icon(preference.icon, size: 18),
                  label: Text(preference.label),
                ),
            ],
            selected: {selected},
            onSelectionChanged: (selection) {
              controller.setThemePreference(selection.first);
            },
          ),
        ],
      ),
    );
  }
}

class _ImpactStrip extends StatelessWidget {
  const _ImpactStrip({
    required this.donations,
    required this.totalVolumeMl,
    required this.points,
  });

  final int donations;
  final int totalVolumeMl;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ImpactItem(
            label: 'Lần hiến',
            value: '$donations',
            icon: Icons.favorite_border,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ImpactItem(
            label: 'Đã ghi nhận',
            value:
                '${NumberFormat.compact(locale: 'vi').format(totalVolumeMl)} ml',
            icon: Icons.water_drop_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ImpactItem(
            label: 'Điểm',
            value: NumberFormat.compact(locale: 'vi').format(points),
            icon: Icons.stars_outlined,
          ),
        ),
      ],
    );
  }
}

class _ImpactItem extends StatelessWidget {
  const _ImpactItem({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PulseLinkTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PulseLinkTheme.subtleBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PulseLinkTheme.primaryRed, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: PulseLinkTheme.textColor(context),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: PulseLinkTheme.mutedColor(context),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
    final notifications = controller.state.notifications;
    final unreadCount = notifications.where((n) => n.unread).length;

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Image.asset('assets/images/pulse_link_icon.png'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào, hiệp sĩ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PulseLinkTheme.mutedColor(context),
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
          onPressed: () => _showNotifications(context, controller),
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount.toString()),
            child: const Icon(Icons.notifications_active_outlined),
          ),
          tooltip: 'Thông báo',
        ),
      ],
    );
  }
  Future<void> _showNotifications(
    BuildContext context,
    PulseLinkController controller,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: PulseLinkTheme.surfaceColor(context),
      builder: (context) {
        final notifications = controller.state.notifications;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông báo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                if (notifications.isEmpty)
                  Text(
                    'Chưa có thông báo mới.',
                    style: TextStyle(
                      color: PulseLinkTheme.mutedColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: PulseLinkTheme.subtleBorderColor(context),
                            ),
                          ),
                          tileColor: notification.unread
                              ? PulseLinkTheme.primaryRed.withOpacity(0.08)
                              : PulseLinkTheme.surfaceColor(context),
                          title: Text(
                            notification.title,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              notification.body,
                              style: TextStyle(
                                color: PulseLinkTheme.mutedColor(context),
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          onTap: () {
                            controller.markNotificationRead(notification.id);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
    final statusLabel = switch (appointment.status) {
      DonationAppointmentStatus.booked => 'Đang chờ tham gia',
      DonationAppointmentStatus.checkedIn => 'Đã check-in',
      DonationAppointmentStatus.deferred => 'Tạm hoãn sau khám',
      DonationAppointmentStatus.completed => 'Đã hoàn thành',
      DonationAppointmentStatus.noShow => 'Không đến',
      DonationAppointmentStatus.cancelled => 'Đã hủy',
    };

    return Material(
      color: PulseLinkTheme.surfaceColor(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: PulseLinkTheme.subtleBorderColor(context)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onOpenDetails,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor:
                        PulseLinkTheme.primaryRed.withOpacity(0.08),
                    child: const Icon(
                      Icons.event_available_outlined,
                      color: PulseLinkTheme.successGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: PulseLinkTheme.textColor(context),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${DateFormat('dd/MM/yyyy - HH:mm').format(event.startsAt)}\n${event.locationName}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: PulseLinkTheme.mutedColor(context),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: const TextStyle(
                          color: PulseLinkTheme.successGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appointment.bookedAt == null
                            ? 'Đã xác nhận lịch'
                            : 'Đặt lúc ${DateFormat('dd/MM/yyyy - HH:mm').format(appointment.bookedAt!)}',
                        style: TextStyle(
                          color: PulseLinkTheme.mutedColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (appointment.canCancel)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Hủy lịch'),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.lock_outline,
                      color: PulseLinkTheme.mutedColor(context),
                      size: 18,
                    ),
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
    super.key,
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
        color: PulseLinkTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PulseLinkTheme.subtleBorderColor(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: PulseLinkTheme.primaryRed, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: PulseLinkTheme.textColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: PulseLinkTheme.mutedColor(context)),
          ),
        ],
      ),
    );
  }
}

class _PreparationChecklist extends StatelessWidget {
  const _PreparationChecklist({
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = [
      'Ngủ đủ và ăn nhẹ trước khi đến.',
      'Uống nước, tránh rượu bia trước ngày hiến.',
      'Mang giấy tờ tùy thân hoặc mã Hero Pass.',
      'Nếu thấy mệt, sốt hoặc chưa yên tâm, hãy dời lịch.',
    ];

    return Container(
      padding: EdgeInsets.all(compact ? 0 : 14),
      decoration: compact
          ? null
          : BoxDecoration(
              color: PulseLinkTheme.surfaceColor(context),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: PulseLinkTheme.subtleBorderColor(context)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            Text(
              'Trước khi đến điểm hiến',
              style: TextStyle(
                color: PulseLinkTheme.textColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
          ],
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: PulseLinkTheme.successGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: compact
                          ? const Color(0xFF475569)
                          : PulseLinkTheme.mutedText,
                      height: 1.35,
                      fontSize: compact ? 13 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (item != items.last) const SizedBox(height: 7),
          ],
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
                      color: PulseLinkTheme.mutedColor(context),
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
        color: PulseLinkTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PulseLinkTheme.subtleBorderColor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: PulseLinkTheme.primaryRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: PulseLinkTheme.mutedColor(context)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: PulseLinkTheme.textColor(context),
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

class _DonationPromoCard extends StatefulWidget {
  const _DonationPromoCard({required this.controller});

  final PulseLinkController controller;

  @override
  State<_DonationPromoCard> createState() => _DonationPromoCardState();
}

class _DonationPromoCardState extends State<_DonationPromoCard> {
  DonationCampaign? _featured;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadFeatured();
  }

  Future<void> _loadFeatured() async {
    try {
      final campaigns = await widget.controller.donationFundService.getCampaigns();
      if (!mounted) return;
      DonationCampaign? pick;
      if (campaigns.isNotEmpty) {
        // Ưu tiên chiến dịch cấp thiết nhất, còn lại lấy cái mới nhất.
        const rank = {'critical': 3, 'urgent': 2, 'normal': 1};
        final sorted = [...campaigns]..sort((a, b) {
            final ra = rank[a.urgencyLevel] ?? 0;
            final rb = rank[b.urgencyLevel] ?? 0;
            return rb.compareTo(ra);
          });
        pick = sorted.first;
      }
      setState(() {
        _featured = pick;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  void _openCampaigns() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DonationCampaignsScreen(controller: widget.controller),
      ),
    );
  }

  void _openFeatured() {
    final campaign = _featured;
    if (campaign == null) {
      _openCampaigns();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DonationDetailScreen(
          controller: widget.controller,
          campaignId: campaign.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fallback tĩnh khi chưa tải được / không có chiến dịch: giữ CTA đơn giản.
    if (!_loaded || _featured == null) {
      return _buildSimpleCta(isDark);
    }

    return _buildStoryCard(isDark, _featured!);
  }

  Widget _buildSimpleCta(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openCampaigns,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DonationPalette.surface(isDark).withOpacity(isDark ? 0.6 : 1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: DonationPalette.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DonationPalette.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volunteer_activism_rounded, color: DonationPalette.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đồng hành quyên góp',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: DonationPalette.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chung tay cùng những hoàn cảnh đang cần bạn.',
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: DonationPalette.mutedText(isDark)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCard(bool isDark, DonationCampaign c) {
    final isFinancial = c.isFinancial;
    final progress = isFinancial ? c.financialProgress : c.pointsProgress;
    final percent = (progress * 100).round();
    final urgency = DonationPalette.urgency(c.urgencyLevel);
    final beneficiary = (c.beneficiaryName ?? '').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openFeatured,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: DonationPalette.surface(isDark),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DonationPalette.primary.withOpacity(0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: DonationPalette.primary.withOpacity(isDark ? 0.12 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh + overlay + badge cấp thiết
              Stack(
                children: [
                  SizedBox(
                    height: 128,
                    width: double.infinity,
                    child: c.imageUrl != null
                        ? Image.network(
                            c.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imageFallback(),
                          )
                        : _imageFallback(),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        const _PromoTag(
                          icon: Icons.volunteer_activism_rounded,
                          label: 'Đồng hành quyên góp',
                          color: DonationPalette.primary,
                        ),
                        if (urgency != null) ...[
                          const SizedBox(width: 8),
                          _PromoTag(icon: urgency.icon, label: urgency.label, color: urgency.color),
                        ],
                      ],
                    ),
                  ),
                  if (beneficiary.isNotEmpty)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 10,
                      child: Text(
                        beneficiary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: DonationPalette.strongText(isDark),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Progress
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress == 0 ? null : progress,
                        minHeight: 7,
                        backgroundColor: DonationPalette.primary.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(DonationPalette.primary),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Đã cùng góp $percent%',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: DonationPalette.primary,
                          ),
                        ),
                        const Spacer(),
                        if (c.donorCount > 0) ...[
                          Icon(Icons.favorite_rounded, size: 13, color: DonationPalette.coral),
                          const SizedBox(width: 4),
                          Text(
                            '${c.donorCount} người đồng hành',
                            style: TextStyle(fontSize: 12, color: DonationPalette.mutedText(isDark)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: DonationPalette.warmGradient),
      child: const Center(
        child: Icon(Icons.favorite_rounded, color: Colors.white70, size: 40),
      ),
    );
  }
}

class _PromoTag extends StatelessWidget {
  const _PromoTag({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

