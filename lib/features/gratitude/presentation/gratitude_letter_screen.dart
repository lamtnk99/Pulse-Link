import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/pulse_link_theme.dart';
import '../../../core/utils/haptics.dart';
import '../domain/gratitude_letter.dart';

class GratitudeLetterScreen extends StatefulWidget {
  const GratitudeLetterScreen({
    super.key,
    required this.letter,
    required this.onClose,
    this.onOpenCare,
  });

  final GratitudeLetter letter;
  final VoidCallback onClose;
  final VoidCallback? onOpenCare;

  @override
  State<GratitudeLetterScreen> createState() => _GratitudeLetterScreenState();
}

class _GratitudeLetterScreenState extends State<GratitudeLetterScreen>
    with TickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  late final AnimationController _entryController;
  late final AnimationController _envelopeController;
  late final AnimationController _floatController;
  late String _selectedStyle;
  bool _opened = false;
  bool _saving = false;

  static const _styles = [
    _LetterVisualStyle.classic(),
    _LetterVisualStyle.heroNight(),
    _LetterVisualStyle.botanical(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStyle = _styles.any((style) => style.id == widget.letter.style)
        ? widget.letter.style
        : _styles.first.id;
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _envelopeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _envelopeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visualStyle(_selectedStyle);
    final letter = widget.letter.copyWithStyle(_selectedStyle);
    final fade =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entryController, curve: Curves.easeOutCubic));

    return Scaffold(
      backgroundColor: visual.backdropEnd,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [visual.backdropStart, visual.backdropEnd],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, _) => CustomPaint(
                painter: _GratitudeParticlePainter(
                  progress: _floatController.value,
                  accent: visual.accent,
                  soft: visual.softAccent,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Đóng',
                      ),
                      const Spacer(),
                      if (letter.isSos)
                        _HeroPill(
                          icon: Icons.emergency_share_rounded,
                          label: 'SOS',
                          visual: visual,
                        )
                      else
                        _HeroPill(
                          icon: Icons.water_drop_rounded,
                          label: 'Hiến máu',
                          visual: visual,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                    child: FadeTransition(
                      opacity: fade,
                      child: SlideTransition(
                        position: slide,
                        child: Column(
                          children: [
                            _HeartBeacon(visual: visual),
                            const SizedBox(height: 18),
                            Text(
                              letter.heroTitle.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                height: 1.22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Text(
                                letter.heroSubtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.78),
                                  fontSize: 14,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            GestureDetector(
                              onTap: _opened ? null : _openEnvelope,
                              child: _EnvelopeReveal(
                                animation: _envelopeController,
                                visual: visual,
                                opened: _opened,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 420),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: _opened
                                  ? Column(
                                      key: const ValueKey('opened-letter'),
                                      children: [
                                        AnimatedBuilder(
                                          animation: _envelopeController,
                                          builder: (context, child) {
                                            final curved =
                                                Curves.easeOutCubic.transform(
                                              _envelopeController.value,
                                            );
                                            return Opacity(
                                              opacity: curved,
                                              child: Transform.translate(
                                                offset: Offset(
                                                    0, 26 * (1 - curved)),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: RepaintBoundary(
                                            key: _cardKey,
                                            child: _ThankYouLetterCard(
                                              letter: letter,
                                              visual: visual,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        _StyleSelector(
                                          styles: _styles,
                                          selected: _selectedStyle,
                                          onChanged: (value) {
                                            Haptics.tap();
                                            setState(
                                                () => _selectedStyle = value);
                                          },
                                        ),
                                        const SizedBox(height: 18),
                                        _ActionBar(
                                          saving: _saving,
                                          hasCare: letter.hasCareConversation &&
                                              widget.onOpenCare != null,
                                          onSave: () =>
                                              _captureCard(share: false),
                                          onShare: () =>
                                              _captureCard(share: true),
                                          onOpenCare: widget.onOpenCare,
                                        ),
                                      ],
                                    )
                                  : _ClosedEnvelopeCaption(
                                      key: const ValueKey('closed-envelope'),
                                      visual: visual,
                                      letter: letter,
                                      onOpen: _openEnvelope,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openEnvelope() {
    if (_opened) return;
    Haptics.success();
    setState(() => _opened = true);
    _envelopeController.forward(from: 0);
  }

  _LetterVisualStyle _visualStyle(String id) {
    return _styles.firstWhere(
      (style) => style.id == id,
      orElse: () => _styles.first,
    );
  }

  Future<void> _captureCard({required bool share}) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      final boundary = _cardKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('Card is not ready');
      }

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Could not render card image');
      }

      final file = await _writeImage(bytes);
      if (share) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png')],
            text: 'Thiệp cảm ơn PulseLink',
            fileNameOverrides: [file.uri.pathSegments.last],
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            share ? 'Đã chuẩn bị thiệp để chia sẻ.' : 'Đã lưu thiệp cảm ơn.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa lưu được thiệp. Thử lại sau vài giây nhé.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<File> _writeImage(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(
      '${directory.path}${Platform.pathSeparator}pulselink_thiep_cam_on_$stamp.png',
    );
    return file.writeAsBytes(bytes, flush: true);
  }
}

class _HeartBeacon extends StatelessWidget {
  const _HeartBeacon({required this.visual});

  final _LetterVisualStyle visual;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: 0.75 + value * 0.25, child: child);
      },
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              visual.accent.withOpacity(0.95),
              visual.accent.withOpacity(0.16),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: visual.accent.withOpacity(0.38),
              blurRadius: 34,
              spreadRadius: 6,
            ),
          ],
        ),
        child:
            const Icon(Icons.favorite_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _EnvelopeReveal extends StatelessWidget {
  const _EnvelopeReveal({
    required this.animation,
    required this.visual,
    required this.opened,
  });

  final Animation<double> animation;
  final _LetterVisualStyle visual;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final open = Curves.easeOutCubic.transform(animation.value);
        return SizedBox(
          height: 210,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              if (!opened)
                Positioned(
                  bottom: 10,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.92, end: 1.08),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    onEnd: () {},
                    child: Container(
                      width: 250,
                      height: 118,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: visual.accent.withOpacity(0.22),
                            blurRadius: 44,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(0, -58 * open),
                child: Opacity(
                  opacity: opened ? 0.22 + open * 0.78 : 0,
                  child: Container(
                    width: 184,
                    height: 104,
                    decoration: BoxDecoration(
                      color: visual.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: visual.border),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.favorite_rounded,
                        color: visual.accent.withOpacity(0.52),
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              CustomPaint(
                size: const Size(292, 150),
                painter: _EnvelopePainter(
                  open: open,
                  visual: visual,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClosedEnvelopeCaption extends StatelessWidget {
  const _ClosedEnvelopeCaption({
    super.key,
    required this.visual,
    required this.letter,
    required this.onOpen,
  });

  final _LetterVisualStyle visual;
  final GratitudeLetter letter;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final sender = letter.messages.first.sender;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: FilledButton.tonalIcon(
        onPressed: onOpen,
        icon: Icon(Icons.mark_email_unread_rounded, color: visual.accent),
        label: Text(
          'Mở thư từ $sender',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.12),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: Colors.white.withOpacity(0.14)),
          ),
        ),
      ),
    );
  }
}

class _ThankYouLetterCard extends StatelessWidget {
  const _ThankYouLetterCard({
    required this.letter,
    required this.visual,
  });

  final GratitudeLetter letter;
  final _LetterVisualStyle visual;

  @override
  Widget build(BuildContext context) {
    final date = letter.donatedAt == null
        ? null
        : DateFormat('dd/MM/yyyy').format(letter.donatedAt!);
    final meta = [
      if (letter.bloodType != null) 'Nhóm ${letter.bloodType}',
      if (letter.volumeMl != null) '${letter.volumeMl}ml',
      if (date != null) date,
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          color: visual.paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: visual.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: visual.accent.withOpacity(0.12),
                    border: Border.all(color: visual.accent.withOpacity(0.22)),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: visual.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        letter.messages.first.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: visual.ink,
                          fontSize: 17,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Từ ${letter.messages.first.sender}',
                        style: TextStyle(
                          color: visual.mutedInk,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (letter.donorName != null && letter.donorName!.trim().isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gửi ${letter.donorName!},',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: visual.ink,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gửi bạn,',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: visual.ink,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            if (letter.hospitalName != null &&
                letter.hospitalName!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  letter.hospitalName!,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: visual.mutedInk,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            ...letter.messages.map(
              (message) => _LetterParagraph(
                message: message,
                visual: visual,
                showSender: letter.messages.length > 1,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '- ${letter.messages.last.signature} -',
                style: TextStyle(
                  color: visual.mutedInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: meta
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: visual.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: visual.accent.withOpacity(0.18)),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            color: visual.ink,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              letter.isSos
                  ? 'Một hành động nhỏ hôm nay có thể là sự sống của một ai đó ngày mai.'
                  : 'Cảm ơn bạn đã lan tỏa yêu thương và hy vọng.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: visual.accent,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterParagraph extends StatelessWidget {
  const _LetterParagraph({
    required this.message,
    required this.visual,
    required this.showSender,
  });

  final GratitudeLetterMessage message;
  final _LetterVisualStyle visual;
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSender) ...[
            Text(
              message.sender,
              style: TextStyle(
                color: visual.accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            message.body,
            style: TextStyle(
              color: visual.ink.withOpacity(0.91),
              fontSize: 15,
              height: 1.62,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleSelector extends StatelessWidget {
  const _StyleSelector({
    required this.styles,
    required this.selected,
    required this.onChanged,
  });

  final List<_LetterVisualStyle> styles;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn kiểu thiệp',
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: styles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final style = styles[index];
                final active = style.id == selected;
                return InkWell(
                  onTap: () => onChanged(style.id),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 132,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: style.paper,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active
                            ? style.accent
                            : Colors.white.withOpacity(0.18),
                        width: active ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(style.icon, color: style.accent, size: 17),
                            const Spacer(),
                            if (active)
                              Icon(Icons.check_circle_rounded,
                                  color: style.accent, size: 18),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          style.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: style.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.saving,
    required this.hasCare,
    required this.onSave,
    required this.onShare,
    this.onOpenCare,
  });

  final bool saving;
  final bool hasCare;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback? onOpenCare;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: saving
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                  label: const Text('Lưu thiệp'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: saving ? null : onShare,
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: 'Chia sẻ',
              ),
            ],
          ),
          if (hasCare) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenCare,
                icon: const Icon(Icons.health_and_safety_rounded),
                label: const Text('Mở chăm sóc sau hiến'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.28)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
    required this.visual,
  });

  final IconData icon;
  final String label;
  final _LetterVisualStyle visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: visual.softAccent, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  const _EnvelopePainter({
    required this.open,
    required this.visual,
  });

  final double open;
  final _LetterVisualStyle visual;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Rect.fromLTWH(0, 36, size.width, size.height - 36);
    final bodyPaint = Paint()..color = visual.envelope;
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rrect = RRect.fromRectAndRadius(body, const Radius.circular(18));
    canvas.drawRRect(rrect, bodyPaint);

    final left = Path()
      ..moveTo(body.left, body.top + 5)
      ..lineTo(size.width / 2, body.center.dy + 22)
      ..lineTo(body.left, body.bottom)
      ..close();
    final right = Path()
      ..moveTo(body.right, body.top + 5)
      ..lineTo(size.width / 2, body.center.dy + 22)
      ..lineTo(body.right, body.bottom)
      ..close();
    canvas.drawPath(left, Paint()..color = visual.envelopeShadow);
    canvas.drawPath(
        right, Paint()..color = visual.envelopeShadow.withOpacity(0.9));

    final flapLift = 32 * open;
    final flap = Path()
      ..moveTo(body.left + 8, body.top + 2)
      ..lineTo(size.width / 2, body.top + 72 - flapLift)
      ..lineTo(body.right - 8, body.top + 2)
      ..close();
    canvas.drawPath(
      flap,
      Paint()
        ..color = Color.lerp(visual.envelopeShadow, visual.envelope, open)!,
    );

    canvas.drawRRect(rrect, borderPaint);
    final sealCenter = Offset(size.width / 2, body.top + 55 - 10 * open);
    canvas.drawCircle(
        sealCenter, 20, Paint()..color = visual.accent.withOpacity(0.95));
    _drawHeart(canvas, sealCenter, 10, Paint()..color = Colors.white);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.58);
    path.cubicTo(
      center.dx - size * 1.25,
      center.dy - size * 0.15,
      center.dx - size * 0.74,
      center.dy - size,
      center.dx,
      center.dy - size * 0.38,
    );
    path.cubicTo(
      center.dx + size * 0.74,
      center.dy - size,
      center.dx + size * 1.25,
      center.dy - size * 0.15,
      center.dx,
      center.dy + size * 0.58,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EnvelopePainter oldDelegate) {
    return oldDelegate.open != open || oldDelegate.visual != visual;
  }
}

class _GratitudeParticlePainter extends CustomPainter {
  const _GratitudeParticlePainter({
    required this.progress,
    required this.accent,
    required this.soft,
  });

  final double progress;
  final Color accent;
  final Color soft;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 18; i++) {
      final seed = i * 37.0;
      final x =
          ((math.sin(seed) * 0.5 + 0.5) * size.width + i * 11) % size.width;
      final travel = (progress + i * 0.071) % 1;
      final y = size.height * (1.05 - travel * 1.15);
      final radius = 1.8 + (i % 4) * 0.8;
      final opacity =
          (0.08 + (i % 5) * 0.025) * (1 - (travel - 0.5).abs() * 0.7);
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color =
              (i.isEven ? accent : soft).withOpacity(opacity.clamp(0.02, 0.16)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GratitudeParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

@immutable
class _LetterVisualStyle {
  const _LetterVisualStyle({
    required this.id,
    required this.label,
    required this.icon,
    required this.backdropStart,
    required this.backdropEnd,
    required this.paper,
    required this.ink,
    required this.mutedInk,
    required this.accent,
    required this.softAccent,
    required this.border,
    required this.envelope,
    required this.envelopeShadow,
    this.darkPaper = false,
  });

  const _LetterVisualStyle.classic()
      : this(
          id: 'classic',
          label: 'Trang nhã',
          icon: Icons.local_florist_rounded,
          backdropStart: const Color(0xFF10233D),
          backdropEnd: const Color(0xFF061424),
          paper: const Color(0xFFFFFBF7),
          ink: const Color(0xFF172033),
          mutedInk: const Color(0xFF69758B),
          accent: PulseLinkTheme.primaryRed,
          softAccent: const Color(0xFFFFA1AE),
          border: const Color(0xFFF3D9D9),
          envelope: const Color(0xFF102D4F),
          envelopeShadow: const Color(0xFF07172A),
        );

  const _LetterVisualStyle.heroNight()
      : this(
          id: 'hero_night',
          label: 'Đêm SOS',
          icon: Icons.favorite_rounded,
          backdropStart: const Color(0xFF061A33),
          backdropEnd: const Color(0xFF010816),
          paper: const Color(0xFF101D33),
          ink: Colors.white,
          mutedInk: const Color(0xFFBAC8DE),
          accent: const Color(0xFFFF3B58),
          softAccent: const Color(0xFFFFA8B7),
          border: const Color(0xFF31445F),
          envelope: const Color(0xFF0D2746),
          envelopeShadow: const Color(0xFF07182C),
          darkPaper: true,
        );

  const _LetterVisualStyle.botanical()
      : this(
          id: 'botanical',
          label: 'Hy vọng xanh',
          icon: Icons.eco_rounded,
          backdropStart: const Color(0xFF0E2D36),
          backdropEnd: const Color(0xFF061822),
          paper: const Color(0xFFFAFFF8),
          ink: const Color(0xFF12312A),
          mutedInk: const Color(0xFF5E766C),
          accent: const Color(0xFF0FA37F),
          softAccent: const Color(0xFF8CE9D4),
          border: const Color(0xFFD5EADF),
          envelope: const Color(0xFF123A48),
          envelopeShadow: const Color(0xFF082631),
        );

  final String id;
  final String label;
  final IconData icon;
  final Color backdropStart;
  final Color backdropEnd;
  final Color paper;
  final Color ink;
  final Color mutedInk;
  final Color accent;
  final Color softAccent;
  final Color border;
  final Color envelope;
  final Color envelopeShadow;
  final bool darkPaper;
}
