import 'package:flutter/material.dart';

import 'app/pulse_link_bootstrap.dart';
import 'app/pulse_link_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = await PulseLinkBootstrap.createController();

  runApp(PulseLinkApp(controller: controller));
}
