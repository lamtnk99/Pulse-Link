import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import '../infrastructure/notifications/mobile_push_notification_service.dart';
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
  static const _notificationPromptSeenKey =
      'notification_permission_intro_seen_v1';

  final _navigatorKey = GlobalKey<NavigatorState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _notificationPromptCheckRunning = false;
  bool _notificationPromptHandled = false;

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
        _considerNotificationPermissionPrompt(state);

        return MaterialApp(
          navigatorKey: _navigatorKey,
          scaffoldMessengerKey: _scaffoldMessengerKey,
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

  void _considerNotificationPermissionPrompt(PulseLinkState state) {
    if (_notificationPromptHandled ||
        _notificationPromptCheckRunning ||
        !widget.controller.pushNotificationsAvailable ||
        state.isLoading ||
        state.profile == null ||
        state.activeMode != AppMode.daily ||
        state.pendingLevelUp != null ||
        state.activeGratitudeLetter != null ||
        state.activeLiveBloodJourney != null) {
      return;
    }

    _notificationPromptCheckRunning = true;
    unawaited(_prepareNotificationPermissionPrompt());
  }

  Future<void> _prepareNotificationPermissionPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyHandled = prefs.getBool(_notificationPromptSeenKey) ?? false;
    final alreadyGranted = await widget.controller.hasPushPermission();

    if (!mounted) return;
    _notificationPromptCheckRunning = false;
    if (alreadyHandled || alreadyGranted) {
      _notificationPromptHandled = true;
      if (alreadyGranted && !alreadyHandled) {
        await prefs.setBool(_notificationPromptSeenKey, true);
      }
      return;
    }

    _notificationPromptHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showNotificationPermissionPrompt(prefs));
    });
  }

  Future<void> _showNotificationPermissionPrompt(
    SharedPreferences prefs,
  ) async {
    final dialogContext = _navigatorKey.currentContext;
    if (!mounted || dialogContext == null) {
      _notificationPromptHandled = false;
      return;
    }

    final shouldEnable = await showDialog<bool>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        icon: const Icon(
          Icons.notifications_active_outlined,
          color: PulseLinkTheme.primaryRed,
          size: 34,
        ),
        title: const Text(
          'Không bỏ lỡ lời kêu gọi SOS',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Bật thông báo để Pulse Link báo ngay khi bệnh viện cần nhóm máu phù hợp, nhắc lịch hiến và gửi hướng dẫn chăm sóc sau hiến.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Để sau'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.notifications_outlined),
            label: const Text('Bật thông báo'),
          ),
        ],
      ),
    );

    await prefs.setBool(_notificationPromptSeenKey, true);
    if (shouldEnable != true || !mounted) return;

    final status = await widget.controller.requestPushPermission();
    if (!mounted || status == PushPermissionStatus.granted) return;

    final message = status == PushPermissionStatus.denied
        ? 'Bạn có thể bật thông báo sau trong Hồ sơ hoặc Cài đặt thiết bị.'
        : 'Chưa thể bật Firebase push trên thiết bị này.';
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
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
