import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/pulse_link_theme.dart';
import '../../../../core/utils/vietnamese_labels.dart';
import '../../domain/donation_event.dart';

typedef DonationEventAction = FutureOr<void> Function(DonationEvent event);

class EventMapPreview extends StatelessWidget {
  const EventMapPreview({
    super.key,
    required this.events,
    this.onOpenDetails,
    this.onBookingToggle,
    this.onOpenDirections,
    this.onOpenFullMap,
    this.fullscreen = false,
  });

  final List<DonationEvent> events;
  final DonationEventAction? onOpenDetails;
  final DonationEventAction? onBookingToggle;
  final DonationEventAction? onOpenDirections;
  final VoidCallback? onOpenFullMap;
  final bool fullscreen;

  @override
  Widget build(BuildContext context) {
    final map = _TileEventMap(
      events: events,
      fullscreen: fullscreen,
      onEventTap: (event) => _showEventSheet(context, event),
    );

    if (fullscreen) {
      return Stack(
        children: [
          Positioned.fill(child: map),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: _MapHud(count: events.length, fullscreen: true),
          ),
          const Positioned(
            left: 16,
            bottom: 16,
            child: _AttributionBadge(),
          ),
        ],
      );
    }

    return AspectRatio(
      aspectRatio: 1.55,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFEFF5F9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: map),
              Positioned(
                left: 14,
                top: 14,
                right: 14,
                child: _MapHud(
                  count: events.length,
                  onOpenFullMap: onOpenFullMap,
                ),
              ),
              const Positioned(
                left: 14,
                bottom: 12,
                child: _AttributionBadge(compact: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEventSheet(
    BuildContext context,
    DonationEvent event,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: PulseLinkTheme.cardBackground,
      builder: (sheetContext) {
        return _EventMapSheet(
          event: event,
          onOpenDetails: onOpenDetails == null
              ? null
              : () async {
                  Navigator.of(sheetContext).pop();
                  await onOpenDetails!(event);
                },
          onBookingToggle: onBookingToggle == null
              ? null
              : () async {
                  Navigator.of(sheetContext).pop();
                  await onBookingToggle!(event);
                },
          onOpenDirections: onOpenDirections == null
              ? null
              : () async {
                  Navigator.of(sheetContext).pop();
                  await onOpenDirections!(event);
                },
        );
      },
    );
  }
}

class _TileEventMap extends StatelessWidget {
  const _TileEventMap({
    required this.events,
    required this.fullscreen,
    required this.onEventTap,
  });

  final List<DonationEvent> events;
  final bool fullscreen;
  final ValueChanged<DonationEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    final camera = _MapCamera.fromEvents(events);

    return FlutterMap(
      options: MapOptions(
        initialCenter: camera.center,
        initialZoom: fullscreen ? camera.zoom : math.min(camera.zoom, 12.5),
        maxZoom: 18,
        minZoom: 5,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag |
              InteractiveFlag.flingAnimation |
              InteractiveFlag.pinchMove |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.scrollWheelZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.pulselink.app',
        ),
        MarkerLayer(
          markers: [
            for (final event in events)
              Marker(
                point: LatLng(
                  event.location.latitude,
                  event.location.longitude,
                ),
                width: 54,
                height: 64,
                alignment: Alignment.topCenter,
                child: _EventMarker(
                  event: event,
                  onTap: () => onEventTap(event),
                ),
              ),
          ],
        ),
        if (events.isEmpty)
          const Align(
            alignment: Alignment.center,
            child: _EmptyMapMessage(),
          ),
      ],
    );
  }
}

class _EventMarker extends StatelessWidget {
  const _EventMarker({
    required this.event,
    required this.onTap,
  });

  final DonationEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        event.booked ? PulseLinkTheme.successGreen : PulseLinkTheme.primaryRed;

    return Tooltip(
      message: event.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.34),
                      blurRadius: 18,
                      spreadRadius: 5,
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  event.booked
                      ? Icons.check_rounded
                      : Icons.water_drop_outlined,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              CustomPaint(
                size: const Size(14, 10),
                painter: _MarkerTailPainter(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkerTailPainter extends CustomPainter {
  const _MarkerTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MarkerTailPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _MapHud extends StatelessWidget {
  const _MapHud({
    required this.count,
    this.onOpenFullMap,
    this.fullscreen = false,
  });

  final int count;
  final VoidCallback? onOpenFullMap;
  final bool fullscreen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.58),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_outlined, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fullscreen
                        ? '$count điểm hiến máu trên bản đồ'
                        : '$count điểm hiến máu gần bạn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onOpenFullMap != null) ...[
          const SizedBox(width: 8),
          Material(
            color: PulseLinkTheme.primaryRed,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onOpenFullMap,
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                height: 38,
                width: 38,
                child: Icon(Icons.open_in_full_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AttributionBadge extends StatelessWidget {
  const _AttributionBadge({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 4 : 5,
        ),
        child: Text(
          compact ? 'OSM' : '© OpenStreetMap',
          style: TextStyle(
            color: const Color(0xFF334155),
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyMapMessage extends StatelessWidget {
  const _EmptyMapMessage();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          'Chưa có điểm hiến máu phù hợp',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EventMapSheet extends StatelessWidget {
  const _EventMapSheet({
    required this.event,
    this.onOpenDetails,
    this.onBookingToggle,
    this.onOpenDirections,
  });

  final DonationEvent event;
  final VoidCallback? onOpenDetails;
  final VoidCallback? onBookingToggle;
  final VoidCallback? onOpenDirections;

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${DateFormat('dd/MM/yyyy').format(event.startsAt)} · ${DateFormat('HH:mm').format(event.startsAt)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: PulseLinkTheme.primaryRed.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: PulseLinkTheme.primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      VietnameseLabels.text(event.title),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      dateText,
                      style: const TextStyle(
                        color: PulseLinkTheme.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SheetInfo(
            icon: Icons.location_on_outlined,
            text: VietnameseLabels.text(event.locationName),
          ),
          const SizedBox(height: 8),
          _SheetInfo(
            icon: Icons.near_me_outlined,
            text:
                '${event.distanceKm.toStringAsFixed(1)} km · còn ${event.slotsLeft} suất',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenDirections,
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Chỉ đường'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenDetails,
                  icon: const Icon(Icons.article_outlined),
                  label: const Text('Chi tiết'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: event.slotsLeft <= 0 && !event.booked
                  ? null
                  : onBookingToggle,
              icon: Icon(
                event.booked
                    ? Icons.event_busy_outlined
                    : Icons.calendar_month_outlined,
              ),
              label: Text(event.booked ? 'Hủy lịch đã đặt' : 'Đặt lịch'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetInfo extends StatelessWidget {
  const _SheetInfo({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: PulseLinkTheme.primaryRed),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: PulseLinkTheme.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapCamera {
  const _MapCamera({
    required this.center,
    required this.zoom,
  });

  factory _MapCamera.fromEvents(List<DonationEvent> events) {
    if (events.isEmpty) {
      return const _MapCamera(
        center: LatLng(20.8449, 106.6881),
        zoom: 11,
      );
    }

    var minLat = events.first.location.latitude;
    var maxLat = minLat;
    var minLng = events.first.location.longitude;
    var maxLng = minLng;

    for (final event in events.skip(1)) {
      minLat = math.min(minLat, event.location.latitude);
      maxLat = math.max(maxLat, event.location.latitude);
      minLng = math.min(minLng, event.location.longitude);
      maxLng = math.max(maxLng, event.location.longitude);
    }

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );
    final span = math.max(maxLat - minLat, maxLng - minLng);

    return _MapCamera(
      center: center,
      zoom: _zoomForSpan(span),
    );
  }

  final LatLng center;
  final double zoom;

  static double _zoomForSpan(double span) {
    if (span <= 0.02) return 14;
    if (span <= 0.08) return 12.5;
    if (span <= 0.25) return 11;
    if (span <= 0.8) return 9.5;
    if (span <= 2.4) return 8;
    return 6;
  }
}
