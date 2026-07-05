import 'package:flutter/material.dart';

import '../core/enums/app_mode.dart';
import '../core/enums/app_theme_preference.dart';
import '../core/theme/pulse_link_theme.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/daily/presentation/daily_mode_screen.dart';
import '../features/emergency/presentation/sos_mode_screen.dart';
import '../features/emergency/presentation/live_blood_journey_screen.dart';
import '../features/profile/presentation/hero_level_up_screen.dart';
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

class _PulseLinkAppState extends State<PulseLinkApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.handleAppResumed();
    }
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
          theme: PulseLinkTheme.themeForMode(
            state.activeMode,
            brightness: Brightness.light,
          ),
          darkTheme: PulseLinkTheme.themeForMode(
            state.activeMode,
            brightness: Brightness.dark,
          ),
          themeMode: state.themePreference.themeMode,
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: state.isLoading
                ? const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : state.profile == null
                    ? LoginScreen(
                        key: const ValueKey('login-screen'),
                        controller: widget.controller,
                      )
                    : state.pendingLevelUp != null
                        ? HeroLevelUpScreen(
                            key: ValueKey('hero-level-up-${state.pendingLevelUp}'),
                            newLevel: state.pendingLevelUp!,
                            badgeTitle: state.profile?.badgeTitle ?? '',
                            onDismiss: widget.controller.dismissLevelUp,
                          )
                    : state.activeLiveBloodJourney != null
                        ? LiveBloodJourneyScreen(
                            key: const ValueKey('live-blood-journey'),
                            bloodJourney: state.activeLiveBloodJourney!,
                            hospitalName: state.activeLiveBloodJourneyHospitalName ?? 'Bệnh viện',
                            bloodType: state.activeLiveBloodJourneyBloodType ?? 'O',
                            onClose: widget.controller.clearActiveLiveBloodJourney,
                          )
                        : state.activeMode == AppMode.sos
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
