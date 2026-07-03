import 'package:url_launcher/url_launcher.dart';

import '../../domain/emergency_alert.dart';

enum SosRideProvider {
  grab,
  be,
  xanhSm,
}

extension SosRideProviderDisplay on SosRideProvider {
  String get label {
    return switch (this) {
      SosRideProvider.grab => 'Grab',
      SosRideProvider.be => 'be',
      SosRideProvider.xanhSm => 'Xanh SM',
    };
  }

  String get subtitle {
    return switch (this) {
      SosRideProvider.grab => 'Mở app Grab nếu đã cài',
      SosRideProvider.be => 'Mở app be hoặc trang tải app',
      SosRideProvider.xanhSm => 'Mở app Xanh SM hoặc trang dịch vụ',
    };
  }

  Uri get primaryUri {
    return switch (this) {
      SosRideProvider.grab => Uri.parse('grab://open'),
      SosRideProvider.be => Uri.parse('be://'),
      SosRideProvider.xanhSm => Uri.parse('xanhsm://'),
    };
  }

  Uri get fallbackUri {
    return switch (this) {
      SosRideProvider.grab => Uri.parse('https://www.grab.com/vn/download/'),
      SosRideProvider.be => Uri.parse('https://be.com.vn/tai-ung-dung-be/'),
      SosRideProvider.xanhSm => Uri.parse('https://www.xanhsm.com/'),
    };
  }
}

Future<void> openEmergencyDirections(EmergencyAlert alert) async {
  final label = Uri.encodeComponent(alert.hospitalName);
  final latitude = alert.hospitalLocation.latitude;
  final longitude = alert.hospitalLocation.longitude;
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=$latitude,$longitude'
    '&travelmode=driving'
    '&query=$label',
  );

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}

Future<bool> callEmergencyPhone(String? phone) async {
  final normalized = phone?.replaceAll(RegExp(r'[^0-9+]'), '');
  if (normalized == null || normalized.isEmpty) return false;

  final uri = Uri(scheme: 'tel', path: normalized);
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri);
  }

  return false;
}

Future<void> openRideProvider(SosRideProvider provider) async {
  if (await canLaunchUrl(provider.primaryUri)) {
    final opened = await launchUrl(
      provider.primaryUri,
      mode: LaunchMode.externalApplication,
    );
    if (opened) return;
  }

  await launchUrl(provider.fallbackUri, mode: LaunchMode.externalApplication);
}
