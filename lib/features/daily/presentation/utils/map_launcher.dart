import 'package:url_launcher/url_launcher.dart';

import '../../domain/donation_event.dart';

Future<void> openDonationEventDirections(DonationEvent event) async {
  final encodedLabel = Uri.encodeComponent(event.locationName);
  final latitude = event.location.latitude;
  final longitude = event.location.longitude;
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=$latitude,$longitude'
    '&query=$encodedLabel',
  );

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}
