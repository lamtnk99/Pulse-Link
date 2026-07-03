import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/pulse_link_controller.dart';
import '../../../core/theme/pulse_link_theme.dart';
import '../domain/donation_event.dart';
import 'utils/map_launcher.dart';
import 'widgets/event_map_preview.dart';

class DonationEventDetailScreen extends StatefulWidget {
  const DonationEventDetailScreen({
    super.key,
    required this.controller,
    required this.initialEvent,
  });

  final PulseLinkController controller;
  final DonationEvent initialEvent;

  @override
  State<DonationEventDetailScreen> createState() =>
      _DonationEventDetailScreenState();
}

class _DonationEventDetailScreenState extends State<DonationEventDetailScreen> {
  late Future<DonationEvent> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.controller.loadEventDetail(widget.initialEvent.id);
  }

  Future<void> _toggleBooking(DonationEvent event) async {
    final wasBooked = event.booked;
    if (wasBooked) {
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
    } else {
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
              const _DetailPreparationChecklist(compact: true),
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
    }

    await widget.controller.toggleBooking(event);
    final updated = await widget.controller.loadEventDetail(event.id);
    if (!mounted) return;
    setState(() {
      _future = Future.value(updated);
    });
    if (wasBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lịch đã được hủy. Hẹn bạn khi cơ thể sẵn sàng hơn.'),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Lịch đã được giữ cho bạn'),
          content: Text(
            'Trước ngày hiến, hãy ngủ đủ, ăn nhẹ và uống nước. Nếu thấy người không ổn, hủy lịch cũng là một lựa chọn đúng.\n\n${DateFormat('HH:mm dd/MM/yyyy').format(updated.startsAt)} · ${updated.locationName}',
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openDonationEventDirections(updated);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sự kiện'),
      ),
      body: FutureBuilder<DonationEvent>(
        future: _future,
        initialData: widget.initialEvent,
        builder: (context, snapshot) {
          final event = snapshot.data ?? widget.initialEvent;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 1.55,
                  child: Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white10,
                      alignment: Alignment.center,
                      child: const Icon(Icons.bloodtype, size: 42),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                event.urgency == EventUrgency.high
                    ? 'ĐANG ƯU TIÊN TIẾP NHẬN'
                    : 'LỊCH HIẾN MÁU THƯỜNG QUY',
                style: const TextStyle(
                  color: PulseLinkTheme.primaryRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                event.organizer,
                style: const TextStyle(color: PulseLinkTheme.mutedText),
              ),
              const SizedBox(height: 18),
              _InfoPanel(event: event),
              const SizedBox(height: 16),
              EventMapPreview(
                events: [event],
                onOpenDirections: openDonationEventDirections,
              ),
              const SizedBox(height: 16),
              if (event.description != null && event.description!.isNotEmpty)
                _DescriptionPanel(description: event.description!),
              const SizedBox(height: 16),
              const _DetailPreparationChecklist(),
              const SizedBox(height: 16),
              _HospitalPanel(event: event),
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<DonationEvent>(
        future: _future,
        initialData: widget.initialEvent,
        builder: (context, snapshot) {
          final event = snapshot.data ?? widget.initialEvent;
          final lockedAppointment = event.appointmentStatus != null &&
              event.appointmentStatus != 'booked' &&
              event.appointmentStatus != 'cancelled';
          final buttonLabel = event.booked
              ? 'Hủy lịch đã đặt'
              : lockedAppointment
                  ? _appointmentStatusLabel(event.appointmentStatus!)
                  : 'Đặt lịch hiến máu';
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: FilledButton.icon(
                onPressed:
                    lockedAppointment || (event.slotsLeft <= 0 && !event.booked)
                        ? null
                        : () => _toggleBooking(event),
                icon: Icon(
                  event.booked
                      ? Icons.event_busy_outlined
                      : Icons.calendar_month_outlined,
                ),
                label: Text(buttonLabel),
              ),
            ),
          );
        },
      ),
    );
  }

  String _appointmentStatusLabel(String status) {
    return switch (status) {
      'checked_in' => 'Đã check-in tại điểm hiến',
      'deferred' => 'Tạm hoãn sau khám',
      'completed' => 'Đã hoàn thành hiến máu',
      'no_show' => 'Đã ghi nhận không đến',
      _ => 'Không thể thay đổi lịch',
    };
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.event});

  final DonationEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Thời gian',
            value:
                '${DateFormat('dd/MM/yyyy').format(event.startsAt)} · ${DateFormat('HH:mm').format(event.startsAt)} - ${DateFormat('HH:mm').format(event.endsAt)}',
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Địa điểm',
            value: event.locationName,
          ),
          _InfoRow(
            icon: Icons.map_outlined,
            label: 'Khu vực',
            value: event.province?.fullName ??
                '${event.location.latitude.toStringAsFixed(4)}, ${event.location.longitude.toStringAsFixed(4)}',
          ),
          _InfoRow(
            icon: Icons.people_alt_outlined,
            label: 'Chỗ còn lại',
            value:
                '${event.slotsLeft} suất${event.capacity == null ? '' : ' / ${event.capacity} chỉ tiêu'}',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PulseLinkTheme.primaryRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: PulseLinkTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

class _DescriptionPanel extends StatelessWidget {
  const _DescriptionPanel({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        description,
        style: const TextStyle(
          color: Colors.white70,
          height: 1.5,
        ),
      ),
    );
  }
}

class _DetailPreparationChecklist extends StatelessWidget {
  const _DetailPreparationChecklist({
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
      padding: EdgeInsets.all(compact ? 0 : 16),
      decoration: compact
          ? null
          : BoxDecoration(
              color: PulseLinkTheme.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            const Text(
              'Trước khi đến điểm hiến',
              style: TextStyle(
                color: Colors.white,
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

class _HospitalPanel extends StatelessWidget {
  const _HospitalPanel({required this.event});

  final DonationEvent event;

  @override
  Widget build(BuildContext context) {
    final hospital = event.hospital;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white10,
            child: Icon(Icons.local_hospital_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospital?.name ?? event.organizer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hospital?.address ?? 'Đơn vị điều phối sự kiện',
                  style: const TextStyle(
                    color: PulseLinkTheme.mutedText,
                    fontSize: 12,
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
