import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/pulse_link_bootstrap.dart';
import 'app/pulse_link_app.dart';
import 'infrastructure/notifications/mobile_push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(pulseLinkFirebaseBackgroundHandler);

  final controller = await PulseLinkBootstrap.createController();

  runApp(PulseLinkApp(controller: controller));
}
