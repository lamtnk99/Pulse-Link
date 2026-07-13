import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/pulse_link_bootstrap.dart';
import 'app/pulse_link_app.dart';
import 'infrastructure/notifications/mobile_push_notification_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase trước khi gọi bất kỳ API nào của FirebaseMessaging
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Web is supported for running the app, but browser push is intentionally
  // not registered by MobilePushNotificationService. Registering a native
  // background callback there can require a separate messaging service worker.
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(pulseLinkFirebaseBackgroundHandler);
  }

  final controller = await PulseLinkBootstrap.createController();

  runApp(PulseLinkApp(controller: controller));
}
