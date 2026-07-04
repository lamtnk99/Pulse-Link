import '../../features/chat/domain/chat_conversation.dart';
import '../../features/chat/domain/chat_message.dart';
import '../../services/chat_service.dart';
import 'laravel_api_client.dart';

class LaravelChatService implements ChatService {
  const LaravelChatService(this._client);

  final LaravelApiClient _client;

  @override
  Future<List<ChatConversation>> getConversations() async {
    final list = await _client.getList('/api/mobile/me/chats');
    return list
        .cast<Map<String, dynamic>>()
        .map(ChatConversation.fromJson)
        .toList(growable: false);
  }

  @override
  Future<ChatConversation> getConversation(String id) async {
    final json = await _client.getJson('/api/mobile/me/chats/$id');
    return ChatConversation.fromJson(_unwrapData(json));
  }

  @override
  Future<ChatConversation> createConversation({
    String? contextType,
    Map<String, dynamic>? contextMeta,
  }) async {
    final json = await _client.postJson(
      '/api/mobile/me/chats',
      body: {
        if (contextType != null) 'context_type': contextType,
        if (contextMeta != null) 'context_meta': contextMeta,
      },
    );
    return ChatConversation.fromJson(_unwrapData(json));
  }

  @override
  Future<ChatMessage> sendMessage(String conversationId, String content) async {
    final json = await _client.postJson(
      '/api/mobile/me/chats/$conversationId/messages',
      body: {'content': content},
    );
    return ChatMessage.fromJson(_unwrapData(json));
  }

  @override
  Future<ChatConversation?> getActiveCheckup() async {
    try {
      final json = await _client.getJson('/api/mobile/me/chats/active-checkup');
      final data = json['data'];
      if (data == null) return null;
      return ChatConversation.fromJson(_unwrapData(json));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getQuota() async {
    final json = await _client.getJson('/api/mobile/me/chats/quota');
    return _unwrapData(json);
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }
}
