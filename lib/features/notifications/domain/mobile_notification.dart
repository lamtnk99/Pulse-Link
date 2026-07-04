class MobileNotification {
  const MobileNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.payload = const {},
    this.readAt,
  });

  factory MobileNotification.fromJson(Map<String, dynamic> json) {
    return MobileNotification(
      id: (json['id'] as Object).toString(),
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? 'Pulse Link',
      body: json['body'] as String? ?? '',
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : const {},
      readAt: _parseDate(json['read_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get unread => readAt == null;
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
