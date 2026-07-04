import 'package:flutter/material.dart';
import '../../../core/theme/pulse_link_theme.dart';
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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkActiveCheckup() async {
    try {
      final activeCheckup = await widget.controller.chatService.getActiveCheckup();
      if (activeCheckup != null && mounted) {
        setState(() {
          _hasActiveCheckup = true;
        });
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
                  screenHeight - _fabSize - mediaQuery.padding.bottom - _edgePadding,
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
              setState(() {
                _isOpen = true;
                _hasActiveCheckup = false; // Dismiss badge on click
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
                  // Glowing FAB core
                  Container(
                    height: _fabSize,
                    width: _fabSize,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE31837), Color(0xFFB91C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE31837).withOpacity(0.35),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
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
                              color: Color(0xFF10B981), // Green for health care dot
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
              setState(() {
                _isOpen = false;
              });
            },
          ),
      ],
    );
  }
}
