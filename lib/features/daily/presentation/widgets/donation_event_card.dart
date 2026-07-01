import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/pulse_link_theme.dart';
import '../../../../core/utils/vietnamese_labels.dart';
import '../../domain/donation_event.dart';

class DonationEventCard extends StatelessWidget {
  const DonationEventCard({
    super.key,
    required this.event,
    required this.onBookingToggle,
    this.expanded = false,
    this.onOpenDetails,
  });

  final DonationEvent event;
  final VoidCallback onBookingToggle;
  final bool expanded;
  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        mainAxisSize: expanded ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            VietnameseLabels.text(event.title),
            maxLines: expanded ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          _IconText(
            icon: Icons.event_outlined,
            text:
                '${DateFormat('dd/MM/yyyy').format(event.startsAt)} - ${DateFormat('HH:mm').format(event.startsAt)}',
          ),
          const SizedBox(height: 4),
          _IconText(
            icon: Icons.location_on_outlined,
            text: VietnameseLabels.text(event.locationName),
          ),
          if (expanded) const SizedBox(height: 10) else const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Còn ${event.slotsLeft} suất',
                  style: const TextStyle(
                    color: PulseLinkTheme.successGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: event.slotsLeft <= 0 && !event.booked
                    ? null
                    : onBookingToggle,
                icon: Icon(
                  event.booked
                      ? Icons.check_circle
                      : Icons.calendar_month_outlined,
                  size: 18,
                ),
                label: Text(event.booked ? 'Đã đặt' : 'Đặt lịch'),
              ),
            ],
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: PulseLinkTheme.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: expanded ? 142 : 112,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        event.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: Colors.white10,
                            alignment: Alignment.center,
                            child: const Icon(Icons.bloodtype, size: 36),
                          );
                        },
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.72),
                            ],
                          ),
                        ),
                      ),
                      if (event.urgency == EventUrgency.high)
                        const Positioned(
                          left: 10,
                          top: 10,
                          child: _UrgencyBadge(),
                        ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: _DistanceBadge(distanceKm: event.distanceKm),
                      ),
                    ],
                  ),
                ),
                if (expanded) content else Expanded(child: content),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: PulseLinkTheme.primaryRed),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PulseLinkTheme.mutedText,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  const _UrgencyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: PulseLinkTheme.primaryRed.withOpacity(0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'CẦN GẤP',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({
    required this.distanceKm,
  });

  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.near_me_outlined,
            color: PulseLinkTheme.primaryRed,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            '${distanceKm.toStringAsFixed(1)} km',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
