import 'package:flutter/material.dart';

import '../core/enums/app_mode.dart';
import '../core/theme/pulse_link_theme.dart';
import '../features/daily/presentation/daily_mode_screen.dart';
import '../features/emergency/presentation/sos_mode_screen.dart';
import 'pulse_link_controller.dart';

class PulseLinkApp extends StatefulWidget {
  const PulseLinkApp({
    super.key,
    required this.controller,
  });

  final PulseLinkController controller;

  @override
  State<PulseLinkApp> createState() => _PulseLinkAppState();
}

class _PulseLinkAppState extends State<PulseLinkApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.initialize();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Pulse Link',
          theme: PulseLinkTheme.themeForMode(state.activeMode),
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: state.activeMode == AppMode.sos
                ? SosModeScreen(
                    key: const ValueKey('sos-mode'),
                    controller: widget.controller,
                  )
                : DailyModeScreen(
                    key: const ValueKey('daily-mode'),
                    controller: widget.controller,
                  ),
          ),
        );
      },
    );
  }
}
