import 'chat_message.dart';

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.title,
    required this.contextType,
    this.contextMeta,
    required this.isActive,
    required this.createdAt,
    this.latestMessage,
    this.messages,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    List<ChatMessage>? msgs;
    if (json['messages'] is List) {
      msgs = (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return ChatConversation(
      id: (json['id'] ?? '').toString(),
      title: json['title'] as String? ?? 'Cuộc trò chuyện mới',
      contextType: json['context_type'] as String? ?? 'general',
      contextMeta: json['context_meta'] as Map<String, dynamic>?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      latestMessage: json['latest_message'] != null
          ? ChatMessage.fromJson(json['latest_message'] as Map<String, dynamic>)
          : null,
      messages: msgs,
    );
  }

  final String id;
  final String title;
  final String contextType;
  final Map<String, dynamic>? contextMeta;
  final bool isActive;
  final DateTime createdAt;
  final ChatMessage? latestMessage;
  final List<ChatMessage>? messages;

  bool get isPostDonationCheckup => contextType == 'post_donation_checkup';
  bool get isPreDonationGuidance => contextType == 'pre_donation_guidance';
  bool get isAppointmentReminder => contextType == 'appointment_reminder';
  bool get isDonationDeferred => contextType == 'donation_deferred';
  bool get isGeneral => contextType == 'general';
}
