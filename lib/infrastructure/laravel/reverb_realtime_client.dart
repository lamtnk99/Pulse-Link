import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class LaravelRealtimeConfig {
  const LaravelRealtimeConfig({
    required this.enabled,
    required this.key,
    required this.host,
    required this.port,
    required this.scheme,
    required this.globalChannel,
    required this.donorChannelTemplate,
    required this.alertActivatedEvent,
    required this.commitmentUpdatedEvent,
    required this.notificationCreatedEvent,
  });

  factory LaravelRealtimeConfig.fromJson(Map<String, dynamic> json) {
    final channels = json['channels'] is Map<String, dynamic>
        ? json['channels'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final events = json['events'] is Map<String, dynamic>
        ? json['events'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return LaravelRealtimeConfig(
      enabled: json['enabled'] as bool? ?? false,
      key: json['key'] as String? ?? '',
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 443,
      scheme: json['scheme'] as String? ?? 'https',
      globalChannel: channels['global'] as String? ?? 'mobile.emergency-alerts',
      donorChannelTemplate:
          channels['donor'] as String? ?? 'mobile.donor.{donor_id}',
      alertActivatedEvent:
          events['alert_activated'] as String? ?? 'emergency.alert.activated',
      commitmentUpdatedEvent: events['commitment_updated'] as String? ??
          'emergency.commitment.updated',
      notificationCreatedEvent: events['notification_created'] as String? ??
          'mobile.notification.created',
    );
  }

  final bool enabled;
  final String key;
  final String host;
  final int port;
  final String scheme;
  final String globalChannel;
  final String donorChannelTemplate;
  final String alertActivatedEvent;
  final String commitmentUpdatedEvent;
  final String notificationCreatedEvent;

  Uri get websocketUri {
    final websocketScheme = scheme == 'https' ? 'wss' : 'ws';
    final isDefaultPort = (websocketScheme == 'wss' && port == 443) ||
        (websocketScheme == 'ws' && port == 80);

    return Uri(
      scheme: websocketScheme,
      host: host,
      port: isDefaultPort ? null : port,
      path: '/app/$key',
      queryParameters: const {
        'protocol': '7',
        'client': 'pulse-link-flutter',
        'version': '1.0.0',
        'flash': 'false',
      },
    );
  }

  Set<String> channelsFor(String donorId) {
    return {
      globalChannel,
      donorChannelTemplate.replaceAll('{donor_id}', donorId),
    };
  }
}

class ReverbRealtimeEvent {
  const ReverbRealtimeEvent({
    required this.name,
    required this.data,
  });

  final String name;
  final Map<String, dynamic> data;
}

class ReverbRealtimeClient {
  const ReverbRealtimeClient();

  Stream<ReverbRealtimeEvent> watch({
    required LaravelRealtimeConfig config,
    required Set<String> channels,
  }) async* {
    if (!config.enabled || config.key.isEmpty || config.host.isEmpty) return;

    var attempt = 0;
    while (true) {
      WebSocketChannel? channel;
      try {
        channel = WebSocketChannel.connect(config.websocketUri);
        // Hứng lỗi kết nối bất đồng bộ (ví dụ: Connection Refused) trong khối try-catch này
        await channel.ready;
        attempt = 0;

        await for (final rawMessage in channel.stream) {
          final message = _decodePayload(rawMessage);
          if (message == null) continue;

          final eventName = message['event'] as String? ?? '';
          if (eventName == 'pusher:connection_established') {
            for (final channelName in channels) {
              channel.sink.add(jsonEncode({
                'event': 'pusher:subscribe',
                'data': {'channel': channelName},
              }));
            }
            continue;
          }

          if (eventName == 'pusher:ping') {
            channel.sink.add(jsonEncode({'event': 'pusher:pong'}));
            continue;
          }

          if (eventName == config.alertActivatedEvent ||
              eventName == config.commitmentUpdatedEvent ||
              eventName == config.notificationCreatedEvent) {
            yield ReverbRealtimeEvent(
              name: eventName,
              data: _decodeData(message['data']),
            );
          }
        }
      } on Object {
        // Reverb is a live acceleration path. Polling keeps the app usable
        // while the socket reconnects or the VPS proxy restarts.
      } finally {
        await channel?.sink.close();
      }

      attempt = (attempt + 1).clamp(1, 6).toInt();
      await Future<void>.delayed(Duration(seconds: attempt * 2));
    }
  }

  Map<String, dynamic>? _decodePayload(Object? rawMessage) {
    if (rawMessage is! String) return null;
    final decoded = jsonDecode(rawMessage);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Map<String, dynamic> _decodeData(Object? rawData) {
    if (rawData is Map<String, dynamic>) return rawData;
    if (rawData is String && rawData.isNotEmpty) {
      final decoded = jsonDecode(rawData);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return const <String, dynamic>{};
  }
}
