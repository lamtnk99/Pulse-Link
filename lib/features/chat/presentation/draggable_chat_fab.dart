import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/pulse_link_controller.dart';
import 'chat_overlay_panel.dart';

class DraggableChatFab extends StatefulWidget {
  const DraggableChatFab({
    super.key,
    required this.controller,
  });

  final PulseLinkController controller;

  @override
  State<DraggableChatFab> createState() => _DraggableChatFabState();
}

class _DraggableChatFabState extends State<DraggableChatFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  double? _x;
  double? _y;
  bool _isOpen = false;
  bool _hasActiveCheckup = false;
  String? _activeCheckupId;

  static const _readCheckupsKey = 'read_chat_checkups';

  final double _fabSize = 60.0;
  final double _edgePadding = 16.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _checkActiveCheckup();
    widget.controller.addListener(_onControllerChanged);
    _isOpen = widget.controller.isChatOpen;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.isChatOpen != _isOpen && mounted) {
      setState(() {
        _isOpen = widget.controller.isChatOpen;
      });
    }
  }

  Future<void> _checkActiveCheckup() async {
    try {
      final activeCheckup =
          await widget.controller.chatService.getActiveCheckup();
      if (activeCheckup == null || !mounted) return;

      // Chỉ báo chấm đỏ cho các cuộc trò chuyện chăm sóc THẬT (checkup sau hiến,
      // dặn dò trước hiến, hoãn hiến, nhắc lịch) — KHÔNG báo cho chat general/lời
      // chào hàng ngày (backend luôn trả về một conversation nên nếu không lọc sẽ
      // báo mỗi lần mở app).
      final isRealCheckup = activeCheckup.isPostDonationCheckup ||
          activeCheckup.isPreDonationGuidance ||
          activeCheckup.isAppointmentReminder ||
          activeCheckup.isDonationDeferred;
      if (!isRealCheckup) return;

      // Bỏ qua nếu người dùng đã đọc checkup này rồi (lưu cục bộ).
      final prefs = await SharedPreferences.getInstance();
      final read = prefs.getStringList(_readCheckupsKey) ?? [];
      if (read.contains(activeCheckup.id)) return;

      if (mounted) {
        setState(() {
          _hasActiveCheckup = true;
          _activeCheckupId = activeCheckup.id;
        });
      }
    } catch (_) {}
  }

  /// Đánh dấu checkup hiện tại đã đọc để không báo lại sau khi mở app.
  Future<void> _markCheckupRead() async {
    final id = _activeCheckupId;
    if (id == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final read = prefs.getStringList(_readCheckupsKey) ?? [];
      if (!read.contains(id)) {
        await prefs.setStringList(_readCheckupsKey, [...read, id]);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Set initial position: bottom right
    _x ??= screenWidth - _fabSize - _edgePadding;
    _y ??= screenHeight - _fabSize - 120.0; // Above bottom navigation bar

    return Stack(
      children: [
        // Draggable FAB Button
        Positioned(
          left: _x,
          top: _y,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _x = (_x! + details.delta.dx).clamp(
                  _edgePadding,
                  screenWidth - _fabSize - _edgePadding,
                );
                _y = (_y! + details.delta.dy).clamp(
                  mediaQuery.padding.top + _edgePadding,
                  screenHeight -
                      _fabSize -
                      mediaQuery.padding.bottom -
                      _edgePadding,
                );
              });
            },
            onPanEnd: (details) {
              // Snap to closest horizontal edge
              final middle = screenWidth / 2;
              final targetX = (_x! + _fabSize / 2) < middle
                  ? _edgePadding
                  : screenWidth - _fabSize - _edgePadding;

              setState(() {
                _x = targetX;
              });
            },
            onTap: () {
              widget.controller.openChat();
              _markCheckupRead(); // Lưu đã đọc để không báo lại khi mở app
              setState(() {
                _hasActiveCheckup = false; // Tắt chấm đỏ ngay
              });
            },
            child: SizedBox(
              height: _fabSize + 16,
              width: _fabSize + 16,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse wave behind
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final val = _pulseController.value;
                      return Opacity(
                        opacity: (1.0 - val).clamp(0.0, 0.4),
                        child: Transform.scale(
                          scale: 1.0 + (val * 0.45),
                          child: Container(
                            height: _fabSize,
                            width: _fabSize,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE31837),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Glowing 3D AI companion core.
                  AiCompanionAvatar(size: _fabSize),
                  // Notification red dot badge
                  if (_hasActiveCheckup)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        height: 14,
                        width: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 0.5),
                        ),
                        child: Center(
                          child: Container(
                            height: 10,
                            width: 10,
                            decoration: const BoxDecoration(
                              color: Color(
                                  0xFF10B981), // Green for health care dot
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Open Overlay Panel
        if (_isOpen)
          ChatOverlayPanel(
            controller: widget.controller,
            onClose: () {
              widget.controller.closeChat();
            },
          ),
      ],
    );
  }
}
