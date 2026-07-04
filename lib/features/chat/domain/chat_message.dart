class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant' || role == 'system';
}
