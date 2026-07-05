import 'dart:ui';
import 'dart:async';
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
  _DailyQuota({required this.used, required this.limit, required this.remaining});
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

  final List<String> _suggestedChips = [
    'Chế độ ăn sau hiến',
    'Tôi bị chóng mặt',
    'Khi nào được hiến tiếp?',
    'Món ăn bổ máu'
  ];

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

      // 3. Auto open active checkup if exists
      final activeCheckup = await widget.controller.chatService.getActiveCheckup();
      if (activeCheckup != null) {
        await _openConversation(activeCheckup);
      } else if (_conversations.isNotEmpty) {
        // Otherwise load the latest conversation if general
        await _openConversation(_conversations.first);
      } else {
        // If absolutely no chats, start a new one
        await _startNewConversation();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không tải được dữ liệu chatbot. Vui lòng kiểm tra kết nối API.';
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
      final fullChat = await widget.controller.chatService.getConversation(conversation.id);
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
        _errorMessage = 'Gửi thất bại hoặc vượt quá giới hạn tin nhắn hàng ngày.';
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
              color: Colors.black.withOpacity(0.65),
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
                    color: PulseLinkTheme.dailyBackground.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE31837).withOpacity(0.12),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildQuotaBar(),
                      if (_errorMessage != null) _buildErrorBanner(),
                      Expanded(child: _buildChatBody()),
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
    final isCheckup = _currentChat?.isPostDonationCheckup ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBackground.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // AI robot avatar
          const RobotMedicalAvatar(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isCheckup ? 'Hỏi thăm sức khỏe' : 'Trợ lý Sức khỏe',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  isCheckup ? 'Mạch Sống đồng hành cùng bạn' : 'Hỏi đáp sức khỏe & hiến máu',
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
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white70),
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
      color: Colors.white.withOpacity(0.03),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Hạn mức tin nhắn AI trong ngày:',
            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            'Còn lại ${_quota!.remaining}/${_quota!.limit}',
            style: TextStyle(
              color: _quota!.remaining <= 3 ? const Color(0xFFE31837) : const Color(0xFF10B981),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE31837).withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Color(0xFFFF8A9A), fontSize: 11, fontWeight: FontWeight.bold),
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
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFFE31837),
              size: 40,
            ),
            const SizedBox(height: 16),
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
              children: _suggestedChips.map((chipText) {
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
                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
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
                : Colors.white.withOpacity(0.04),
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
        decoration: BoxDecoration(
          color: PulseLinkTheme.cardBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              height: 6,
              width: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFE31837),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final hasRemaining = _quota == null || _quota!.remaining != 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBackground.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.06),
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
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: PulseLinkTheme.cardBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            decoration: BoxDecoration(
              gradient: const LinearGradient(
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
                          color: isSelected ? const Color(0xFFE31837) : Colors.white54,
                          size: 20,
                        ),
                        title: Text(
                          chat.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFFE31837) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          chat.contextType == 'post_donation_checkup'
                              ? 'Hỏi thăm sức khỏe'
                              : 'Trò chuyện chung',
                          style: const TextStyle(color: Colors.white30, fontSize: 10),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
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

class RobotMedicalAvatar extends StatefulWidget {
  const RobotMedicalAvatar({super.key, this.size = 44.0});
  final double size;

  @override
  State<RobotMedicalAvatar> createState() => _RobotMedicalAvatarState();
}

class _RobotMedicalAvatarState extends State<RobotMedicalAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkController;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    // Blinks every 3.5 seconds
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (mounted) {
        _blinkController.forward().then((_) {
          if (mounted) {
            _blinkController.reverse();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Glossy Neck / Collar support (adds 3D depth)
          Positioned(
            bottom: size * 0.04,
            child: Container(
              width: size * 0.3,
              height: size * 0.14,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF475569), Color(0xFF1E293B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(size * 0.04),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
            ),
          ),
          // Side ear caps/plates (adds 3D robot aesthetic)
          Positioned(
            left: size * 0.02,
            child: _buildEarCap(size),
          ),
          Positioned(
            right: size * 0.02,
            child: _buildEarCap(size),
          ),
          // Head Spherical Face (Radial gradient for 3D metallic volume)
          Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE31837), // Pulse red outer glow border
                width: 1.5,
              ),
              gradient: const RadialGradient(
                colors: [
                  Color(0xFF334155), // Slate 700 (light reflection point at center-top)
                  Color(0xFF0F172A), // Slate 900 (shadow edge)
                ],
                center: Alignment(-0.15, -0.2),
                radius: 0.85,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE31837).withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ],
            ),
          ),
          // Screen Reflection Glare (glossy 3D overlay)
          Positioned(
            top: size * 0.18,
            left: size * 0.22,
            child: Container(
              width: size * 0.2,
              height: size * 0.08,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: const BorderRadius.all(Radius.elliptical(20, 8)),
              ),
            ),
          ),
          // Blinking Glowing Cyan Eyes
          Positioned(
            top: size * 0.38,
            child: AnimatedBuilder(
              animation: _blinkController,
              builder: (context, child) {
                return Transform.scale(
                  scaleY: 1.0 - _blinkController.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGlowingEye(size),
                      SizedBox(width: size * 0.16),
                      _buildGlowingEye(size),
                    ],
                  ),
                );
              },
            ),
          ),
          // Empathetic Rosy Cheeks
          Positioned(
            top: size * 0.54,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRosyCheek(size),
                SizedBox(width: size * 0.32),
                _buildRosyCheek(size),
              ],
            ),
          ),
          // Nurse/Medical Cap (Enlarged, detailed 3D curves)
          Positioned(
            top: -size * 0.08,
            child: _buildNurseHat(size),
          ),
        ],
      ),
    );
  }

  Widget _buildEarCap(double size) {
    return Container(
      width: size * 0.12,
      height: size * 0.22,
      decoration: BoxDecoration(
        color: const Color(0xFF64748B), // Slate 500
        borderRadius: BorderRadius.circular(size * 0.04),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
      ),
    );
  }

  Widget _buildGlowingEye(double size) {
    return Container(
      width: size * 0.12,
      height: size * 0.12,
      decoration: const BoxDecoration(
        color: Color(0xFF38BDF8), // Cyan sky glow
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0EA5E9),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        // Small white reflection point inside eye for extra life
        child: Container(
          width: size * 0.03,
          height: size * 0.03,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildRosyCheek(double size) {
    return Container(
      width: size * 0.09,
      height: size * 0.05,
      decoration: BoxDecoration(
        color: const Color(0xFFE31837).withOpacity(0.45),
        borderRadius: BorderRadius.all(Radius.elliptical(size * 0.09, size * 0.05)),
      ),
    );
  }

  Widget _buildNurseHat(double size) {
    final hatWidth = size * 0.65;
    final hatHeight = size * 0.28;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Nurse Cap base with curvy border radius
        Container(
          width: hatWidth,
          height: hatHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(size * 0.16),
              topRight: Radius.circular(size * 0.16),
              bottomLeft: Radius.circular(size * 0.04),
              bottomRight: Radius.circular(size * 0.04),
            ),
            border: Border.all(
              color: const Color(0xFFCBD5E1), // Slate 300 edge line
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
        ),
        // Nurse hat blue/red stripe at the bottom edge (traditional medical cap detail)
        Positioned(
          bottom: 0,
          child: Container(
            width: hatWidth,
            height: size * 0.04,
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A), // Dark blue trim
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(2)),
            ),
          ),
        ),
        // Enlarged Bold Red Cross (bold sign)
        Positioned(
          top: hatHeight * 0.15,
          child: _buildBoldRedCross(size * 0.18),
        ),
      ],
    );
  }

  Widget _buildBoldRedCross(double size) {
    final thickness = size * 0.28;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: thickness,
          decoration: BoxDecoration(
            color: const Color(0xFFE31837),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        Container(
          width: thickness,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFE31837),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

