import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

Future<String> saveGratitudeCardImage({
  required Uint8List bytes,
  required String filename,
}) async {
  if (Platform.isAndroid || Platform.isIOS) {
    await Gal.putImageBytes(
      bytes,
      album: 'PulseLink',
      name: filename.replaceFirst(RegExp(r'\.png$', caseSensitive: false), ''),
    );

    return 'thư viện ảnh PulseLink';
  }

  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes, flush: true);

  return file.path;
}
