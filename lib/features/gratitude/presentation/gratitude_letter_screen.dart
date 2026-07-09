import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/haptics.dart';
import '../domain/gratitude_letter.dart';
import 'gratitude_card_exporter.dart';

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

enum _LetterRevealPhase { closed, opening, opened }

class _GratitudeLetterScreenState extends State<GratitudeLetterScreen>
    with TickerProviderStateMixin {
  static const _readPreferencePrefix = 'gratitude_letter_read';

  final GlobalKey _cardKey = GlobalKey();
  late final AnimationController _entryController;
  late final AnimationController _envelopeController;
  late final AnimationController _floatController;
  _LetterRevealPhase _revealPhase = _LetterRevealPhase.closed;
  bool _readStateLoaded = false;
  bool _saving = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
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
    _restoreReadState();
  }

  @override
  void didUpdateWidget(covariant GratitudeLetterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_readPreferenceKeyFor(oldWidget.letter) ==
        _readPreferenceKeyFor(widget.letter)) {
      return;
    }

    _envelopeController.reset();
    setState(() {
      _revealPhase = _LetterRevealPhase.closed;
      _readStateLoaded = false;
    });
    _restoreReadState();
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
    final visual = _LetterVisualStyle.fromId(widget.letter.style);
    final letter = widget.letter;
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
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 520),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final curved = CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                  reverseCurve: Curves.easeInCubic,
                                );
                                return FadeTransition(
                                  opacity: curved,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.035),
                                      end: Offset.zero,
                                    ).animate(curved),
                                    child: child,
                                  ),
                                );
                              },
                              child: !_readStateLoaded
                                  ? const SizedBox(
                                      key: ValueKey('letter-state-loading'),
                                      height: 250,
                                    )
                                  : _revealPhase == _LetterRevealPhase.opened
                                      ? Column(
                                          key: const ValueKey('opened-letter'),
                                          children: [
                                            RepaintBoundary(
                                              key: _cardKey,
                                              child: _ThankYouLetterCard(
                                                letter: letter,
                                                visual: visual,
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            _ShareActionPanel(
                                              saving: _saving,
                                              sharing: _sharing,
                                              onSave: () =>
                                                  _captureCard(share: false),
                                              onShare: () =>
                                                  _captureCard(share: true),
                                            ),
                                            if (letter.hasCareConversation &&
                                                widget.onOpenCare != null) ...[
                                              const SizedBox(height: 18),
                                              _CareActionButton(
                                                onOpenCare: widget.onOpenCare!,
                                              ),
                                            ],
                                          ],
                                        )
                                      : Column(
                                          key: const ValueKey('envelope-stage'),
                                          children: [
                                            GestureDetector(
                                              onTap: _revealPhase ==
                                                      _LetterRevealPhase.closed
                                                  ? _openEnvelope
                                                  : null,
                                              child: _EnvelopeReveal(
                                                animation: _envelopeController,
                                                visual: visual,
                                                phase: _revealPhase,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 220),
                                              child: _revealPhase ==
                                                      _LetterRevealPhase.opening
                                                  ? _OpeningEnvelopeCaption(
                                                      key: const ValueKey(
                                                          'opening-caption'),
                                                      visual: visual,
                                                    )
                                                  : _ClosedEnvelopeCaption(
                                                      key: const ValueKey(
                                                          'closed-envelope'),
                                                      visual: visual,
                                                      letter: letter,
                                                      onOpen: _openEnvelope,
                                                    ),
                                            ),
                                          ],
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

  Future<void> _openEnvelope() async {
    if (_revealPhase != _LetterRevealPhase.closed) return;
    Haptics.success();
    setState(() => _revealPhase = _LetterRevealPhase.opening);
    await _envelopeController.forward(from: 0);
    if (!mounted) return;
    setState(() => _revealPhase = _LetterRevealPhase.opened);
    await _markAsRead();
  }

  Future<void> _restoreReadState() async {
    final prefs = await SharedPreferences.getInstance();
    final wasRead =
        prefs.getBool(_readPreferenceKeyFor(widget.letter)) ?? false;
    if (!mounted) return;
    setState(() {
      _revealPhase =
          wasRead ? _LetterRevealPhase.opened : _LetterRevealPhase.closed;
      _readStateLoaded = true;
    });
  }

  Future<void> _markAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_readPreferenceKeyFor(widget.letter), true);
  }

  String _readPreferenceKeyFor(GratitudeLetter letter) {
    final stableId = letter.certificateId ?? letter.bloodJourneyId ?? letter.id;
    return '$_readPreferencePrefix:${letter.source.name}:${letterSafeId(stableId)}';
  }

  Future<void> _captureCard({required bool share}) async {
    if (_saving || _sharing) return;
    setState(() {
      _saving = !share;
      _sharing = share;
    });

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

      final filename = _exportFilename();
      if (share) {
        await _shareImage(bytes, filename);
      } else {
        final savedPath =
            await saveGratitudeCardImage(bytes: bytes, filename: filename);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã lưu thư tri ân: $savedPath')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            share
                ? 'Chưa chia sẻ được thư. Thử lại sau vài giây nhé.'
                : 'Chưa lưu được thư. Thử lại sau vài giây nhé.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _sharing = false;
        });
      }
    }
  }

  Future<void> _shareImage(Uint8List bytes, String filename) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: filename,
          ),
        ],
        title: 'Thư tri ân PulseLink',
        text:
            'Mình vừa trao đi một mạch sống cùng PulseLink. Cảm ơn vì đã cùng lan tỏa lòng tốt.',
      ),
    );
  }

  String _exportFilename() {
    final cleanId = letterSafeId(widget.letter.certificateId ??
        widget.letter.bloodJourneyId ??
        widget.letter.id);
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    return 'pulselink_thu_tri_an_${cleanId}_$stamp.png';
  }
}

String letterSafeId(String value) {
  final safe = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return safe.isEmpty ? 'thu_tri_an' : safe;
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
        child: Icon(visual.motifIcon, color: Colors.white, size: 32),
      ),
    );
  }
}

class _EnvelopeReveal extends StatelessWidget {
  const _EnvelopeReveal({
    required this.animation,
    required this.visual,
    required this.phase,
  });

  final Animation<double> animation;
  final _LetterVisualStyle visual;
  final _LetterRevealPhase phase;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final raw = phase == _LetterRevealPhase.closed ? 0.0 : animation.value;
        final open = Curves.easeOutBack.transform(
          const Interval(0.08, 0.5).transform(raw),
        );
        final paperLift = Curves.easeOutCubic.transform(
          const Interval(0.22, 0.76).transform(raw),
        );
        final sealOut = Curves.easeIn.transform(
          const Interval(0, 0.2).transform(raw),
        );
        final exit = Curves.easeInCubic.transform(
          const Interval(0.72, 1).transform(raw),
        );
        final envelopeOpacity = 1 - exit;
        final closed = phase == _LetterRevealPhase.closed;

        return SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              if (closed)
                Positioned(
                  bottom: 24,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.94, end: 1.06),
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
                offset: Offset(0, -116 * paperLift + 18 * exit),
                child: Opacity(
                  opacity:
                      closed ? 0 : (0.1 + paperLift * 0.9) * envelopeOpacity,
                  child: Transform.scale(
                    scale: 0.82 + paperLift * 0.18,
                    child: _EmergingLetterPreview(visual: visual),
                  ),
                ),
              ),
              Opacity(
                opacity: envelopeOpacity.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 34 * exit),
                  child: Transform.scale(
                    scale: 1 - exit * 0.04,
                    child: CustomPaint(
                      size: const Size(292, 150),
                      painter: _EnvelopePainter(
                        open: open.clamp(0.0, 1.0),
                        sealOpacity: (1 - sealOut).clamp(0.0, 1.0),
                        visual: visual,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmergingLetterPreview extends StatelessWidget {
  const _EmergingLetterPreview({required this.visual});

  final _LetterVisualStyle visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 214,
      height: 132,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: visual.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: visual.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            visual.motifIcon,
            color: visual.accent.withOpacity(0.58),
            size: 26,
          ),
          const SizedBox(height: 14),
          _PreviewLine(width: 138, visual: visual),
          const SizedBox(height: 8),
          _PreviewLine(width: 168, visual: visual),
          const SizedBox(height: 8),
          _PreviewLine(width: 112, visual: visual),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    required this.width,
    required this.visual,
  });

  final double width;
  final _LetterVisualStyle visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 5,
      decoration: BoxDecoration(
        color: visual.mutedInk.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
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

class _OpeningEnvelopeCaption extends StatelessWidget {
  const _OpeningEnvelopeCaption({
    super.key,
    required this.visual,
  });

  final _LetterVisualStyle visual;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(visual.softAccent),
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Đang mở thư...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
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
        child: Stack(
          children: [
            Positioned(
              right: 4,
              top: 36,
              child: _LetterHeartCluster(visual: visual),
            ),
            Column(
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
                        border:
                            Border.all(color: visual.accent.withOpacity(0.22)),
                      ),
                      child: Icon(
                        visual.motifIcon,
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    letter.donorName != null &&
                            letter.donorName!.trim().isNotEmpty
                        ? 'Gửi ${letter.donorName!},'
                        : 'Gửi bạn,',
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
          ],
        ),
      ),
    );
  }
}

class _LetterHeartCluster extends StatelessWidget {
  const _LetterHeartCluster({required this.visual});

  final _LetterVisualStyle visual;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.14,
        child: SizedBox(
          width: 120,
          height: 150,
          child: Stack(
            children: [
              _softHeart(72, 12, 34),
              _softHeart(38, 44, 22),
              _softHeart(92, 62, 20),
              _softHeart(16, 92, 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _softHeart(double left, double top, double size) {
    return Positioned(
      left: left,
      top: top,
      child: Icon(
        visual.motifIcon,
        size: size,
        color: visual.accent,
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

class _CareActionButton extends StatelessWidget {
  const _CareActionButton({required this.onOpenCare});

  final VoidCallback onOpenCare;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onOpenCare,
          icon: const Icon(Icons.health_and_safety_rounded),
          label: const Text('Mở chăm sóc sau hiến'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.28)),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }
}

class _ShareActionPanel extends StatelessWidget {
  const _ShareActionPanel({
    required this.saving,
    required this.sharing,
    required this.onSave,
    required this.onShare,
  });

  final bool saving;
  final bool sharing;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final disabled = saving || sharing;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.055),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Column(
              children: [
                const _SharePanelRow(
                  icon: Icons.favorite_border_rounded,
                  title: 'Bạn vừa trao đi sự sống',
                  subtitle: 'Cảm ơn bạn đã trở thành người hùng thầm lặng.',
                  onTap: null,
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.12)),
                _SharePanelRow(
                  icon: Icons.share_rounded,
                  title: sharing
                      ? 'Đang chuẩn bị chia sẻ...'
                      : 'Chia sẻ lòng tốt của bạn',
                  subtitle:
                      'Mở Zalo, Facebook, Messenger hoặc ứng dụng có sẵn.',
                  onTap: disabled ? null : onShare,
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFE93A56),
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: disabled ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(saving ? 'Đang lưu thư...' : 'Lưu thư tri ân'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE93A56),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withOpacity(0.16),
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SharePanelRow extends StatelessWidget {
  const _SharePanelRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE93A56).withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFFFF4667), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
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
    required this.sealOpacity,
    required this.visual,
  });

  final double open;
  final double sealOpacity;
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
    if (sealOpacity > 0) {
      final sealCenter = Offset(size.width / 2, body.top + 55 - 10 * open);
      canvas.drawCircle(
        sealCenter,
        20 * (0.84 + sealOpacity * 0.16),
        Paint()..color = visual.accent.withOpacity(0.95 * sealOpacity),
      );
      _drawHeart(
        canvas,
        sealCenter,
        10 * (0.86 + sealOpacity * 0.14),
        Paint()..color = Colors.white.withOpacity(sealOpacity),
      );
    }
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
    return oldDelegate.open != open ||
        oldDelegate.sealOpacity != sealOpacity ||
        oldDelegate.visual != visual;
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
    required this.motifIcon,
  });

  const _LetterVisualStyle.appreciation()
      : this(
          id: 'classic',
          backdropStart: const Color(0xFF071D38),
          backdropEnd: const Color(0xFF020B1A),
          paper: const Color(0xFFFFF7EF),
          ink: const Color(0xFF342236),
          mutedInk: const Color(0xFF8A6B72),
          accent: const Color(0xFFE93A56),
          softAccent: const Color(0xFFFFB5C1),
          border: const Color(0xFFF1C8CF),
          envelope: const Color(0xFF0B2748),
          envelopeShadow: const Color(0xFF041326),
          motifIcon: Icons.favorite_rounded,
        );

  static const _styles = <_LetterVisualStyle>[
    _LetterVisualStyle.appreciation(),
    _LetterVisualStyle(
      id: 'hero_night',
      backdropStart: Color(0xFF061A35),
      backdropEnd: Color(0xFF010713),
      paper: Color(0xFFFFF3EA),
      ink: Color(0xFF301D29),
      mutedInk: Color(0xFF82616A),
      accent: Color(0xFFE93557),
      softAccent: Color(0xFFFF9CB2),
      border: Color(0xFFF3B9C4),
      envelope: Color(0xFF071F42),
      envelopeShadow: Color(0xFF020C1E),
      motifIcon: Icons.favorite_rounded,
    ),
    _LetterVisualStyle(
      id: 'botanical',
      backdropStart: Color(0xFF103828),
      backdropEnd: Color(0xFF03140F),
      paper: Color(0xFFFFFBEF),
      ink: Color(0xFF243429),
      mutedInk: Color(0xFF667B68),
      accent: Color(0xFF4E9B68),
      softAccent: Color(0xFFBDE8C4),
      border: Color(0xFFCFE7BD),
      envelope: Color(0xFF194A35),
      envelopeShadow: Color(0xFF082016),
      motifIcon: Icons.eco_rounded,
    ),
    _LetterVisualStyle(
      id: 'rose_dawn',
      backdropStart: Color(0xFF4A1431),
      backdropEnd: Color(0xFF130711),
      paper: Color(0xFFFFF2F4),
      ink: Color(0xFF3B1F2C),
      mutedInk: Color(0xFF8C5A68),
      accent: Color(0xFFD83D6A),
      softAccent: Color(0xFFFFB6C8),
      border: Color(0xFFF4B3C2),
      envelope: Color(0xFF5B1C39),
      envelopeShadow: Color(0xFF2A0B1D),
      motifIcon: Icons.local_florist_rounded,
    ),
    _LetterVisualStyle(
      id: 'cherry_bloom',
      backdropStart: Color(0xFF3A163B),
      backdropEnd: Color(0xFF130816),
      paper: Color(0xFFFFF7FA),
      ink: Color(0xFF34233D),
      mutedInk: Color(0xFF866477),
      accent: Color(0xFFE65A82),
      softAccent: Color(0xFFFFC0D3),
      border: Color(0xFFF4C6D5),
      envelope: Color(0xFF421B47),
      envelopeShadow: Color(0xFF1A0B20),
      motifIcon: Icons.spa_rounded,
    ),
    _LetterVisualStyle(
      id: 'sunrise_hope',
      backdropStart: Color(0xFF4B2941),
      backdropEnd: Color(0xFF140E1B),
      paper: Color(0xFFFFF5E8),
      ink: Color(0xFF3E2A21),
      mutedInk: Color(0xFF8B6F55),
      accent: Color(0xFFE16C45),
      softAccent: Color(0xFFFFC18A),
      border: Color(0xFFF1C59B),
      envelope: Color(0xFF5B2F3B),
      envelopeShadow: Color(0xFF23111A),
      motifIcon: Icons.wb_sunny_rounded,
    ),
    _LetterVisualStyle(
      id: 'ocean_breeze',
      backdropStart: Color(0xFF083955),
      backdropEnd: Color(0xFF031119),
      paper: Color(0xFFF2FCFF),
      ink: Color(0xFF1B3341),
      mutedInk: Color(0xFF597C87),
      accent: Color(0xFF2496B8),
      softAccent: Color(0xFFA9E7F2),
      border: Color(0xFFB8E4EC),
      envelope: Color(0xFF0A4A68),
      envelopeShadow: Color(0xFF042334),
      motifIcon: Icons.water_drop_rounded,
    ),
    _LetterVisualStyle(
      id: 'emerald_care',
      backdropStart: Color(0xFF123A3A),
      backdropEnd: Color(0xFF041314),
      paper: Color(0xFFF4FFF9),
      ink: Color(0xFF1C362F),
      mutedInk: Color(0xFF5D7E74),
      accent: Color(0xFF1EAD84),
      softAccent: Color(0xFFAEEBD8),
      border: Color(0xFFBCE6D3),
      envelope: Color(0xFF15534B),
      envelopeShadow: Color(0xFF06231F),
      motifIcon: Icons.volunteer_activism_rounded,
    ),
    _LetterVisualStyle(
      id: 'violet_grace',
      backdropStart: Color(0xFF281B4E),
      backdropEnd: Color(0xFF0B071A),
      paper: Color(0xFFFBF7FF),
      ink: Color(0xFF2F2440),
      mutedInk: Color(0xFF716282),
      accent: Color(0xFF8C5FE8),
      softAccent: Color(0xFFD6C4FF),
      border: Color(0xFFD8CBF3),
      envelope: Color(0xFF30235E),
      envelopeShadow: Color(0xFF110B29),
      motifIcon: Icons.auto_awesome_rounded,
    ),
    _LetterVisualStyle(
      id: 'golden_hour',
      backdropStart: Color(0xFF3D3320),
      backdropEnd: Color(0xFF11100B),
      paper: Color(0xFFFFFBEC),
      ink: Color(0xFF3B2F21),
      mutedInk: Color(0xFF806F4D),
      accent: Color(0xFFD1912C),
      softAccent: Color(0xFFFFD88B),
      border: Color(0xFFEACB87),
      envelope: Color(0xFF4C3A21),
      envelopeShadow: Color(0xFF1E170D),
      motifIcon: Icons.workspace_premium_rounded,
    ),
    _LetterVisualStyle(
      id: 'pearl_glow',
      backdropStart: Color(0xFF233448),
      backdropEnd: Color(0xFF090E17),
      paper: Color(0xFFFFFCF6),
      ink: Color(0xFF2B313C),
      mutedInk: Color(0xFF707987),
      accent: Color(0xFF6D8BBE),
      softAccent: Color(0xFFD8E4FF),
      border: Color(0xFFD4DAE5),
      envelope: Color(0xFF2E4058),
      envelopeShadow: Color(0xFF101925),
      motifIcon: Icons.diamond_rounded,
    ),
    _LetterVisualStyle(
      id: 'ruby_pulse',
      backdropStart: Color(0xFF4B0E1D),
      backdropEnd: Color(0xFF120407),
      paper: Color(0xFFFFF4F1),
      ink: Color(0xFF3F1C1F),
      mutedInk: Color(0xFF885859),
      accent: Color(0xFFC71F3D),
      softAccent: Color(0xFFFF9CAD),
      border: Color(0xFFF1B3B8),
      envelope: Color(0xFF5B1326),
      envelopeShadow: Color(0xFF240812),
      motifIcon: Icons.monitor_heart_rounded,
    ),
    _LetterVisualStyle(
      id: 'sky_lantern',
      backdropStart: Color(0xFF1A3763),
      backdropEnd: Color(0xFF06101E),
      paper: Color(0xFFF5FAFF),
      ink: Color(0xFF243247),
      mutedInk: Color(0xFF667894),
      accent: Color(0xFF4C8EEA),
      softAccent: Color(0xFFB9D8FF),
      border: Color(0xFFC3D9F2),
      envelope: Color(0xFF213F70),
      envelopeShadow: Color(0xFF0B172B),
      motifIcon: Icons.lightbulb_rounded,
    ),
    _LetterVisualStyle(
      id: 'mint_leaf',
      backdropStart: Color(0xFF173A32),
      backdropEnd: Color(0xFF061511),
      paper: Color(0xFFF6FFF7),
      ink: Color(0xFF20372F),
      mutedInk: Color(0xFF617B69),
      accent: Color(0xFF53B77A),
      softAccent: Color(0xFFC6F1D2),
      border: Color(0xFFCDE8CE),
      envelope: Color(0xFF1E4B41),
      envelopeShadow: Color(0xFF0B201A),
      motifIcon: Icons.local_hospital_rounded,
    ),
    _LetterVisualStyle(
      id: 'coral_smile',
      backdropStart: Color(0xFF4B2431),
      backdropEnd: Color(0xFF140B10),
      paper: Color(0xFFFFF4EF),
      ink: Color(0xFF3A2725),
      mutedInk: Color(0xFF86665E),
      accent: Color(0xFFE85F55),
      softAccent: Color(0xFFFFB6A7),
      border: Color(0xFFF1BCB2),
      envelope: Color(0xFF613036),
      envelopeShadow: Color(0xFF251115),
      motifIcon: Icons.sentiment_satisfied_alt_rounded,
    ),
    _LetterVisualStyle(
      id: 'midnight_hero',
      backdropStart: Color(0xFF111A3D),
      backdropEnd: Color(0xFF030712),
      paper: Color(0xFFF8F7FF),
      ink: Color(0xFF262944),
      mutedInk: Color(0xFF6C6E88),
      accent: Color(0xFF5C7CFA),
      softAccent: Color(0xFFB8C8FF),
      border: Color(0xFFC8D1F8),
      envelope: Color(0xFF172451),
      envelopeShadow: Color(0xFF070C21),
      motifIcon: Icons.shield_rounded,
    ),
    _LetterVisualStyle(
      id: 'lavender_mist',
      backdropStart: Color(0xFF342B55),
      backdropEnd: Color(0xFF100D1B),
      paper: Color(0xFFFFF9FF),
      ink: Color(0xFF352940),
      mutedInk: Color(0xFF7C6D87),
      accent: Color(0xFFA06BD6),
      softAccent: Color(0xFFE2C8FF),
      border: Color(0xFFE1CFEA),
      envelope: Color(0xFF413265),
      envelopeShadow: Color(0xFF171022),
      motifIcon: Icons.nightlight_round,
    ),
    _LetterVisualStyle(
      id: 'amber_kindness',
      backdropStart: Color(0xFF443220),
      backdropEnd: Color(0xFF120E08),
      paper: Color(0xFFFFF9EA),
      ink: Color(0xFF3B3022),
      mutedInk: Color(0xFF836F50),
      accent: Color(0xFFE0A13B),
      softAccent: Color(0xFFFFDCA1),
      border: Color(0xFFEBCB93),
      envelope: Color(0xFF553D24),
      envelopeShadow: Color(0xFF20170D),
      motifIcon: Icons.handshake_rounded,
    ),
    _LetterVisualStyle(
      id: 'lotus_peace',
      backdropStart: Color(0xFF25413C),
      backdropEnd: Color(0xFF091615),
      paper: Color(0xFFFFFBF5),
      ink: Color(0xFF293B37),
      mutedInk: Color(0xFF687D76),
      accent: Color(0xFF77A88B),
      softAccent: Color(0xFFD6EBCB),
      border: Color(0xFFD9E4C6),
      envelope: Color(0xFF2E514A),
      envelopeShadow: Color(0xFF10211E),
      motifIcon: Icons.self_improvement_rounded,
    ),
    _LetterVisualStyle(
      id: 'snow_rose',
      backdropStart: Color(0xFF2A324C),
      backdropEnd: Color(0xFF0B0E18),
      paper: Color(0xFFFFFAFA),
      ink: Color(0xFF2F303E),
      mutedInk: Color(0xFF737181),
      accent: Color(0xFFD84E70),
      softAccent: Color(0xFFFFC6D5),
      border: Color(0xFFE8CBD2),
      envelope: Color(0xFF333D5A),
      envelopeShadow: Color(0xFF101522),
      motifIcon: Icons.ac_unit_rounded,
    ),
  ];

  static _LetterVisualStyle fromId(String id) {
    final normalized = id.trim().toLowerCase();
    for (final style in _styles) {
      if (style.id == normalized) return style;
    }
    return _styles.first;
  }

  final String id;
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
  final IconData motifIcon;
}
