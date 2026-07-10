import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/pulse_link_theme.dart';
import '../../../app/pulse_link_controller.dart';
import '../domain/chat_conversation.dart';
import '../domain/chat_message.dart';

class ChatOverlayPanel extends StatefulWidget {
  const ChatOverlayPanel({
    super.key,
    required this.controller,
    required this.onClose,
  });

  final PulseLinkController controller;
  final VoidCallback onClose;

  @override
  State<ChatOverlayPanel> createState() => _ChatOverlayPanelState();
}

class _DailyQuota {
  _DailyQuota(
      {required this.used, required this.limit, required this.remaining});
  final int used;
  final int limit;
  final int remaining;
}

class _ChatOverlayPanelState extends State<ChatOverlayPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  List<ChatConversation> _conversations = [];
  ChatConversation? _currentChat;
  final List<ChatMessage> _messages = [];

  bool _isLoadingChats = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  _DailyQuota? _quota;
  String? _errorMessage;

  List<String> get _dynamicSuggestedChips {
    final chat = _currentChat;
    if (chat == null) {
      return [
        'Chế độ ăn sau hiến',
        'Tôi bị chóng mặt',
        'Khi nào được hiến tiếp?',
        'Món ăn bổ máu'
      ];
    }

    if (chat.isPostDonationCheckup) {
      return [
        'Tôi thấy rất khỏe',
        'Tôi bị chóng mặt',
        'Vết tiêm bị bầm tím',
        'Cần kiêng gì không?',
      ];
    }
    if (chat.isPreDonationGuidance) {
      return [
        'Tôi cần nhịn ăn không?',
        'Cần mang theo giấy tờ gì?',
        'Ai không được hiến máu?',
        'Có được uống trà/café không?'
      ];
    }
    if (chat.isAppointmentReminder) {
      return [
        'Xem vị trí điểm hiến',
        'Thủ tục đăng ký thế nào?',
        'Nếu hôm nay bị mệt?',
        'Cần uống nước ấm lúc nào?'
      ];
    }
    if (chat.isDonationDeferred) {
      return [
        'Tại sao tôi bị hoãn hiến?',
        'Thực phẩm bổ máu tốt nhất?',
        'Khi nào tôi đăng ký lại được?',
        'Tư vấn nâng cao huyết sắc tố'
      ];
    }

    return [
      'Chế độ ăn sau hiến',
      'Tôi bị chóng mặt',
      'Khi nào được hiến tiếp?',
      'Món ăn bổ máu'
    ];
  }

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _slideController.forward();
    _loadInitialData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingChats = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch quota
      final quotaData = await widget.controller.chatService.getQuota();
      _quota = _DailyQuota(
        used: quotaData['used'] as int? ?? 0,
        limit: quotaData['limit'] as int? ?? 0,
        remaining: quotaData['remaining'] as int? ?? -1,
      );

      // 2. Fetch conversations
      _conversations = await widget.controller.chatService.getConversations();

      // 3. Auto open active checkup or target conversation if exists
      final targetId = widget.controller.activeChatConversationId;
      if (targetId != null) {
        final existing = _conversations.firstWhere(
          (c) => c.id == targetId,
          orElse: () => ChatConversation(
            id: targetId,
            title: 'Trợ lý Sức khỏe',
            contextType: 'general',
            isActive: true,
            createdAt: DateTime.now(),
          ),
        );
        await _openConversation(existing);
      } else {
        final activeCheckup =
            await widget.controller.chatService.getActiveCheckup();
        if (activeCheckup != null) {
          await _openConversation(activeCheckup);
        } else if (_conversations.isNotEmpty) {
          // Otherwise load the latest conversation if general
          await _openConversation(_conversations.first);
        } else {
          // If absolutely no chats, start a new one
          await _startNewConversation();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Không tải được dữ liệu chatbot. Vui lòng kiểm tra kết nối API.';
      });
    } finally {
      setState(() {
        _isLoadingChats = false;
      });
    }
  }

  Future<void> _openConversation(ChatConversation conversation) async {
    setState(() {
      _currentChat = conversation;
      _isLoadingMessages = true;
      _messages.clear();
      _errorMessage = null;
    });

    try {
      final fullChat =
          await widget.controller.chatService.getConversation(conversation.id);
      setState(() {
        _messages.addAll(fullChat.messages ?? []);
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải tin nhắn.';
      });
    } finally {
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  Future<void> _startNewConversation() async {
    setState(() {
      _isLoadingMessages = true;
      _currentChat = null;
      _messages.clear();
      _errorMessage = null;
    });

    try {
      final newChat = await widget.controller.chatService.createConversation();
      _conversations = await widget.controller.chatService.getConversations();
      setState(() {
        _currentChat = newChat;
      });

      // AI greeting message placeholder or load
      await _openConversation(newChat);
    } catch (e) {
      setState(() {
        _errorMessage = 'Không tạo được cuộc trò chuyện mới.';
        _isLoadingMessages = false;
      });
    }
  }

  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty || _isSending || _currentChat == null) return;

    final userContent = text.trim();
    _textController.clear();

    // Optimistically add user message to list
    final tempUserMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: userContent,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(tempUserMsg);
      _isSending = true;
      _errorMessage = null;
    });
    _scrollToBottom();

    try {
      final reply = await widget.controller.chatService.sendMessage(
        _currentChat!.id,
        userContent,
      );

      setState(() {
        _messages.add(reply);
      });

      // Update quota
      final quotaData = await widget.controller.chatService.getQuota();
      setState(() {
        _quota = _DailyQuota(
          used: quotaData['used'] as int? ?? 0,
          limit: quotaData['limit'] as int? ?? 0,
          remaining: quotaData['remaining'] as int? ?? -1,
        );
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _errorMessage =
            'Gửi thất bại hoặc vượt quá giới hạn tin nhắn hàng ngày.';
        // Remove optimistic user message to prevent UI confusion
        _messages.removeWhere((m) => m.id == tempUserMsg.id);
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Background Dim Blur overlay
          GestureDetector(
            onTap: () {
              _slideController.reverse().then((_) => widget.onClose());
            },
            child: Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          // Floating chat panel
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.78,
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  decoration: BoxDecoration(
                    color:
                        PulseLinkTheme.dailyBackground.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE31837).withValues(alpha: 0.12),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildQuotaBar(),
                      _buildAiSafetyNotice(),
                      if (_errorMessage != null) _buildErrorBanner(),
                      Expanded(child: _buildChatBody()),
                      _buildQuickRepliesBar(),
                      _buildInputBar(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title = 'Trợ lý Sức khỏe';
    String desc = 'Hỏi đáp sức khỏe & hiến máu';

    final chat = _currentChat;
    if (chat != null) {
      if (chat.isPostDonationCheckup) {
        title = 'Hỏi thăm sức khỏe';
        desc = 'Mạch Sống đồng hành cùng bạn';
      } else if (chat.isPreDonationGuidance) {
        title = 'Chuẩn bị hiến máu';
        desc = 'Dặn dò an toàn trước ca hiến';
      } else if (chat.isAppointmentReminder) {
        title = 'Nhắc hẹn hôm nay';
        desc = 'Pulse Link đồng hành cùng bạn';
      } else if (chat.isDonationDeferred) {
        title = 'Động viên & Bồi bổ';
        desc = 'Sức khỏe của bạn là ưu tiên số 1';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBackground.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          AiCompanionAvatar(size: 48, isThinking: _isSending),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE31837),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: PulseLinkTheme.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // History/New Chat actions
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white70),
            tooltip: 'Lịch sử chat',
            onPressed: _showConversationsList,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: Colors.white70),
            tooltip: 'Chat mới',
            onPressed: _startNewConversation,
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () {
              _slideController.reverse().then((_) => widget.onClose());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaBar() {
    if (_quota == null || _quota!.limit <= 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.white.withValues(alpha: 0.03),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Hạn mức tin nhắn AI trong ngày:',
            style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold),
          ),
          Text(
            'Còn lại ${_quota!.remaining}/${_quota!.limit}',
            style: TextStyle(
              color: _quota!.remaining <= 3
                  ? const Color(0xFFE31837)
                  : const Color(0xFF10B981),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSafetyNotice() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: Colors.white54),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI chỉ hỗ trợ thông tin chung, không chẩn đoán hay thay thế bác sĩ. Nếu có dấu hiệu bất thường sau hiến máu, hãy liên hệ cơ sở y tế.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 10.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE31837).withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        _errorMessage!,
        style: const TextStyle(
            color: Color(0xFFFF8A9A),
            fontSize: 11,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildChatBody() {
    if (_isLoadingChats || _isLoadingMessages) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE31837)),
      );
    }

    if (_messages.isEmpty) {
      return _buildSuggestionsScreen();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingIndicator();
        }

        final msg = _messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildSuggestionsScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AiCompanionAvatar(size: 122, showOrbit: true),
            const SizedBox(height: 20),
            const Text(
              'Xin chào! Tôi có thể giúp gì cho bạn?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hãy đặt bất kỳ câu hỏi nào về chế độ sinh hoạt, dinh dưỡng sau hiến máu hoặc sức khỏe hàng ngày của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PulseLinkTheme.mutedText,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _dynamicSuggestedChips.map((chipText) {
                return ActionChip(
                  label: Text(
                    chipText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: PulseLinkTheme.cardBackground,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  onPressed: () => _handleSendMessage(chipText),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: msg.isUser
              ? const Color(0xFFE31837)
              : PulseLinkTheme.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: msg.isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
          ),
          border: Border.all(
            color: msg.isUser
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Text(
          msg.content,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.5,
            fontWeight: msg.isUser ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: PulseLinkTheme.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: const AiThinkingDots(),
      ),
    );
  }

  Widget _buildQuickRepliesBar() {
    if (_isLoadingChats ||
        _isLoadingMessages ||
        _messages.isEmpty ||
        _isSending) {
      return const SizedBox.shrink();
    }

    final chips = _dynamicSuggestedChips;
    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final chipText = chips[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                chipText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: PulseLinkTheme.cardBackground,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              onPressed: () => _handleSendMessage(chipText),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    final hasRemaining = _quota == null || _quota!.remaining != 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBackground.withValues(alpha: 0.3),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: hasRemaining && !_isSending,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: hasRemaining
                    ? 'Nhập tin nhắn tư vấn sức khỏe...'
                    : 'Đã hết hạn mức tin nhắn hôm nay...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: PulseLinkTheme.cardBackground,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _handleSendMessage,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE31837), Color(0xFFB91C1C)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: hasRemaining && !_isSending
                  ? () => _handleSendMessage(_textController.text)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showConversationsList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PulseLinkTheme.dailyBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LỊCH SỬ HỘI THOẠI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              if (_conversations.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Chưa có cuộc trò chuyện nào.',
                      style: TextStyle(color: Colors.white30, fontSize: 13),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final chat = _conversations[index];
                      final isSelected = _currentChat?.id == chat.id;

                      return ListTile(
                        leading: Icon(
                          chat.isPostDonationCheckup
                              ? Icons.favorite_rounded
                              : Icons.chat_rounded,
                          color: isSelected
                              ? const Color(0xFFE31837)
                              : Colors.white54,
                          size: 20,
                        ),
                        title: Text(
                          chat.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFE31837)
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          chat.contextType == 'post_donation_checkup'
                              ? 'Hỏi thăm sức khỏe'
                              : 'Trò chuyện chung',
                          style: const TextStyle(
                              color: Colors.white30, fontSize: 10),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: Colors.white24),
                        onTap: () {
                          Navigator.pop(context);
                          _openConversation(chat);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class AiCompanionAvatar extends StatefulWidget {
  const AiCompanionAvatar({
    super.key,
    this.size = 44.0,
    this.isThinking = false,
    this.showOrbit = false,
  });

  final double size;
  final bool isThinking;
  final bool showOrbit;

  @override
  State<AiCompanionAvatar> createState() => _AiCompanionAvatarState();
}

class _AiCompanionAvatarState extends State<AiCompanionAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return AnimatedBuilder(
      animation: _motionController,
      builder: (context, child) {
        final wave = math.sin(_motionController.value * math.pi * 2);
        final scale = widget.isThinking ? 1 + wave * 0.035 : 1.0;
        return Transform.translate(
          offset: Offset(0, wave * size * -0.035),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Semantics(
        label: 'Trợ lý AI Pulse Link đang hoạt động',
        image: true,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (widget.showOrbit)
                _CompanionOrbit(size: size, controller: _motionController),
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE31837).withValues(alpha: 0.32),
                      blurRadius: size * 0.2,
                      spreadRadius: size * 0.02,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/ai_health_companion_3d.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              _CompanionBlinkingEyelids(
                size: size,
                controller: _motionController,
              ),
              if (widget.isThinking)
                Positioned(
                  right: size * 0.01,
                  bottom: size * 0.02,
                  child: Container(
                    width: size * 0.2,
                    height: size * 0.2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF08142E), width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanionBlinkingEyelids extends StatelessWidget {
  const _CompanionBlinkingEyelids({
    required this.size,
    required this.controller,
  });

  final double size;
  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        const start = 0.72;
        const duration = 0.09;
        final phase = (controller.value - start) / duration;
        final blink =
            phase <= 0 || phase >= 1 ? 0.0 : math.sin(phase * math.pi);

        return Positioned(
          top: size * 0.39,
          left: size * 0.29,
          child: IgnorePointer(
            child: Opacity(
              opacity: blink,
              child: Row(
                children: [
                  _eyelid(),
                  SizedBox(width: size * 0.13),
                  _eyelid(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _eyelid() {
    return Container(
      width: size * 0.16,
      height: size * 0.095,
      decoration: BoxDecoration(
        color: const Color(0xFF07152D),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.elliptical(size * 0.1, size * 0.08),
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
            width: size * 0.012,
          ),
        ),
      ),
    );
  }
}

class _CompanionOrbit extends StatelessWidget {
  const _CompanionOrbit({required this.size, required this.controller});

  final double size;
  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.rotate(
          angle: controller.value * math.pi * 2,
          child: SizedBox(
            width: size * 1.22,
            height: size * 1.22,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.28),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: size * 0.075,
                    height: size * 0.075,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE31837),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AiThinkingDots extends StatefulWidget {
  const AiThinkingDots({super.key});

  @override
  State<AiThinkingDots> createState() => _AiThinkingDotsState();
}

class _AiThinkingDotsState extends State<AiThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (_controller.value + index / 3) % 1;
            final lift = math.sin(phase * math.pi) * -5;
            return Transform.translate(
              offset: Offset(0, lift),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                height: 6,
                width: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFE31837),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
