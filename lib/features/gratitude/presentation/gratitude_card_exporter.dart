import 'dart:typed_data';

import 'gratitude_card_exporter_stub.dart'
    if (dart.library.html) 'gratitude_card_exporter_web.dart'
    if (dart.library.io) 'gratitude_card_exporter_io.dart' as exporter;

Future<String> saveGratitudeCardImage({
  required Uint8List bytes,
  required String filename,
}) {
  return exporter.saveGratitudeCardImage(bytes: bytes, filename: filename);
}
