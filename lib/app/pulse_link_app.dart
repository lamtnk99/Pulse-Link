import 'package:flutter/material.dart';

import '../core/enums/app_mode.dart';
import '../core/enums/app_theme_preference.dart';
import '../core/theme/pulse_link_theme.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/daily/presentation/daily_mode_screen.dart';
import '../features/emergency/presentation/live_blood_journey_screen.dart';
import '../features/emergency/presentation/sos_mode_screen.dart';
import '../features/gratitude/domain/gratitude_letter.dart';
import '../features/gratitude/presentation/gratitude_letter_screen.dart';
import '../features/profile/presentation/hero_level_up_screen.dart';
import 'pulse_link_controller.dart';
import 'pulse_link_state.dart';

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
            child: _homeForState(state),
          ),
        );
      },
    );
  }

  Widget _homeForState(PulseLinkState state) {
    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.profile == null) {
      return LoginScreen(
        key: const ValueKey('login-screen'),
        controller: widget.controller,
      );
    }

    if (state.pendingLevelUp != null) {
      return HeroLevelUpScreen(
        key: ValueKey('hero-level-up-${state.pendingLevelUp}'),
        newLevel: state.pendingLevelUp!,
        badgeTitle: state.profile?.badgeTitle ?? '',
        onDismiss: widget.controller.dismissLevelUp,
      );
    }

    final activeGratitude = state.activeGratitudeLetter;
    if (activeGratitude != null) {
      return GratitudeLetterScreen(
        key: ValueKey('gratitude-${activeGratitude.id}'),
        letter: activeGratitude,
        onClose: widget.controller.clearActiveGratitudeLetter,
        onOpenCare: activeGratitude.hasCareConversation
            ? () {
                final conversationId = activeGratitude.conversationId!;
                widget.controller.clearActiveGratitudeLetter();
                widget.controller.openChat(conversationId: conversationId);
              }
            : null,
      );
    }

    final journey = state.activeLiveBloodJourney;
    if (journey != null) {
      if (journey.completedAt != null) {
        return GratitudeLetterScreen(
          key: ValueKey('journey-gratitude-${journey.id}'),
          letter: GratitudeLetter.fromBloodJourney(
            journey,
            profile: state.profile,
            hospitalName:
                state.activeLiveBloodJourneyHospitalName ?? 'Bệnh viện',
            bloodType: state.activeLiveBloodJourneyBloodType ?? 'O',
          ),
          onClose: widget.controller.clearActiveLiveBloodJourney,
        );
      }

      return LiveBloodJourneyScreen(
        key: const ValueKey('live-blood-journey'),
        bloodJourney: journey,
        hospitalName: state.activeLiveBloodJourneyHospitalName ?? 'Bệnh viện',
        bloodType: state.activeLiveBloodJourneyBloodType ?? 'O',
        onClose: widget.controller.clearActiveLiveBloodJourney,
      );
    }

    if (state.activeMode == AppMode.sos) {
      return SosModeScreen(
        key: const ValueKey('sos-mode'),
        controller: widget.controller,
      );
    }

    return DailyModeScreen(
      key: const ValueKey('daily-mode'),
      controller: widget.controller,
    );
  }
}
