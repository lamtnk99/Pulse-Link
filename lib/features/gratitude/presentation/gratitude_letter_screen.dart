import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

enum _LetterRevealPhase { closed, opening, opened }

class _GratitudeLetterScreenState extends State<GratitudeLetterScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _envelopeController;
  late final AnimationController _floatController;
  _LetterRevealPhase _revealPhase = _LetterRevealPhase.closed;

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
    const visual = _LetterVisualStyle.appreciation();
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
                              child: _revealPhase == _LetterRevealPhase.opened
                                  ? Column(
                                      key: const ValueKey('opened-letter'),
                                      children: [
                                        _ThankYouLetterCard(
                                          letter: letter,
                                          visual: visual,
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
                                          duration:
                                              const Duration(milliseconds: 220),
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
            Icons.favorite_rounded,
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
        Icons.favorite_rounded,
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
  });

  const _LetterVisualStyle.appreciation()
      : this(
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
        );

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
}
