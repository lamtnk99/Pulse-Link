import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_link/infrastructure/laravel/reverb_realtime_client.dart';

void main() {
  test('LaravelRealtimeConfig builds Reverb websocket URL and mobile channels',
      () {
    final config = LaravelRealtimeConfig.fromJson({
      'enabled': true,
      'key': 'pulse-link-key',
      'host': 'api.pulselink.asia',
      'port': 443,
      'scheme': 'https',
      'channels': {
        'global': 'mobile.emergency-alerts',
        'donor': 'mobile.donor.{donor_id}',
      },
      'events': {
        'alert_activated': 'emergency.alert.activated',
        'commitment_updated': 'emergency.commitment.updated',
      },
    });

    expect(config.enabled, isTrue);
    expect(
      config.websocketUri.toString(),
      'wss://api.pulselink.asia/app/pulse-link-key?protocol=7&client=pulse-link-flutter&version=1.0.0&flash=false',
    );
    expect(config.channelsFor('13'), {
      'mobile.emergency-alerts',
      'mobile.donor.13',
    });
  });
}
