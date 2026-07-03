import 'package:flutter/material.dart';

import '../../../app/pulse_link_controller.dart';
import '../../../core/theme/pulse_link_theme.dart';
import '../domain/donation_event.dart';
import 'donation_event_detail_screen.dart';
import 'utils/map_launcher.dart';
import 'widgets/event_map_preview.dart';

class DonationEventsMapScreen extends StatelessWidget {
  const DonationEventsMapScreen({
    super.key,
    required this.controller,
    required this.events,
  });

  final PulseLinkController controller;
  final List<DonationEvent> events;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('Bản đồ điểm hiến máu'),
        backgroundColor: const Color(0xFF111827),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: EventMapPreview(
              events: events,
              fullscreen: true,
              onOpenDetails: (event) => _openEventDetail(context, event),
              onBookingToggle: (event) => _toggleBooking(context, event),
              onOpenDirections: openDonationEventDirections,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PulseLinkTheme.cardBackground.withOpacity(0.94),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.touch_app_outlined,
                      color: PulseLinkTheme.primaryRed,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        events.isEmpty
                            ? 'Chưa có sự kiện hiến máu để hiển thị.'
                            : 'Chạm vào marker để xem chi tiết, đặt lịch hoặc mở chỉ đường.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEventDetail(
    BuildContext context,
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

  Future<void> _toggleBooking(
    BuildContext context,
    DonationEvent event,
  ) async {
    await controller.toggleBooking(event);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          event.booked ? 'Đã hủy lịch hiến.' : 'Đặt lịch hiến máu thành công.',
        ),
      ),
    );
  }
}
