import '../features/chat/domain/chat_conversation.dart';
import '../features/chat/domain/chat_message.dart';

abstract interface class ChatService {
  Future<List<ChatConversation>> getConversations();

  Future<ChatConversation> getConversation(String id);

  Future<ChatConversation> createConversation({
    String? contextType,
    Map<String, dynamic>? contextMeta,
  });

  Future<ChatMessage> sendMessage(String conversationId, String content);

  Future<ChatConversation?> getActiveCheckup();

  Future<Map<String, dynamic>> getQuota();
}
