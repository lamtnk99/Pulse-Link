import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/pulse_link_controller.dart';
import '../../../core/theme/pulse_link_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.controller,
  });

  final PulseLinkController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _waveController;

  static const String _apiBaseUrl = String.fromEnvironment(
    'LARAVEL_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Pre-fill a donor account by default for convenience
    _emailController.text = 'quan.tran@pulselink.test';
    _passwordController.text = 'password';
  }

  @override
  void dispose() {
    _waveController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/auth/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final payload = jsonDecode(response.body);

      if (response.statusCode != 200) {
        final message = payload['message'] ??
            payload['errors']?['email']?[0] ??
            'Thông tin đăng nhập không chính xác.';
        throw Exception(message);
      }

      final data = payload['data'];
      final token = data['token'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      // Re-initialize app controller to load profile and connect websockets
      await widget.controller.initialize();
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Custom Test Account Chip with explicit high-contrast readable styling
  Widget _buildQuickLoginChip(String email, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _emailController.text = email;
          _passwordController.text = 'password';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1B2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE31837).withOpacity(0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D1A),
      body: Stack(
        children: [
          // Dynamic Beating Heartbeat Wave Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                return CustomPaint(
                  painter: HeartbeatBackgroundPainter(
                    animationValue: _waveController.value,
                  ),
                );
              },
            ),
          ),
          // Glow effect at top left
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              height: 350,
              width: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE31837).withOpacity(0.06),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          // Glow effect at bottom right
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              height: 400,
              width: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE31837).withOpacity(0.04),
                    blurRadius: 200,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Logo Badge
                    Container(
                      height: 84,
                      width: 84,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE31837).withOpacity(0.24),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/pulse_link_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Project Brand Name "PULSE LINK"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'PULSE ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'LINK',
                          style: TextStyle(
                            color: const Color(0xFFE31837),
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: const Color(0xFFE31837).withOpacity(0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Subtitle representing emergency saving mission
                    const Text(
                      'MẠCH SỐNG KẾT NỐI CỨU NGƯỜI KHẨN CẤP',
                      style: TextStyle(
                        color: Color(0xFFE31837),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Glassmorphic Login Form Card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF091424).withOpacity(0.75),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE31837).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE31837).withOpacity(0.24),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFE31837),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],
                            const Text(
                              'EMAIL NGƯỜI HIẾN',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF0F1B2C),
                                hintText: 'email@domain.com',
                                hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE31837),
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'MẬT KHẨU',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập mật khẩu';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF0F1B2C),
                                hintText: '••••••••',
                                hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE31837),
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Gradient Login Button
                            Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE31837),
                                    Color(0xFFB91C1C),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE31837).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoading ? null : _login,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'ĐĂNG NHẬP',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Link sang màn đăng ký tài khoản mới
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RegisterScreen(controller: widget.controller),
                          ),
                        );
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: 'Chưa có tài khoản? ',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'Đăng ký ngay',
                              style: TextStyle(
                                color: Color(0xFFE31837),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Quick Login Test Accounts Section
                    const Text(
                      'TÀI KHOẢN THỬ NGHIỆM (CLICK ĐỂ ĐIỀN)',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildQuickLoginChip('quan.tran@pulselink.test', 'Minh Quân (O+)'),
                        _buildQuickLoginChip('an.nguyen@pulselink.test', 'Hoài An (O-)'),
                        _buildQuickLoginChip('huy.le@pulselink.test', 'Quang Huy (A+)'),
                        _buildQuickLoginChip('minh.bui@pulselink.test', 'Ngọc Minh - HP'),
                        _buildQuickLoginChip('dai.bui@pulselink.test', 'Đức Đại - HP'),
                        _buildQuickLoginChip('dai.phung@pulselink.test', 'Văn Đại - HN'),
                        _buildQuickLoginChip('quan.dao@pulselink.test', 'Minh Quân - HY'),
                        _buildQuickLoginChip('dan.nguyen@pulselink.test', 'Văn Dân - BN'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Background Custom Painter for Heartbeat Pulse Wave with moving glow segment
class HeartbeatBackgroundPainter extends CustomPainter {
  HeartbeatBackgroundPainter({required this.animationValue});

  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw static medical grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 1.0;

    for (double y = 0; y < height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
    for (double x = 0; x < width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFFE31837).withOpacity(0.18)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Drawing two separate lines: Top (framing Logo) and Bottom (framing Test Accounts)
    final topY = height * 0.22;
    final bottomY = height * 0.82;

    final topPath = _createECGPath(width, topY, 0.15, 0.75);
    final bottomPath = _createECGPath(width, bottomY, 0.25, 0.80);

    // Draw background ECG paths
    canvas.drawPath(topPath, linePaint);
    canvas.drawPath(bottomPath, linePaint);

    // Draw animated glowing segments (staggered by 50% phase offset)
    _drawGlowSegment(canvas, topPath, animationValue);
    _drawGlowSegment(canvas, bottomPath, (animationValue + 0.5) % 1.0);
  }

  Path _createECGPath(double width, double centerY, double beatLeftPct, double beatRightPct) {
    final path = Path();
    path.moveTo(0, centerY);

    final leftBeatStart = width * beatLeftPct;
    final rightBeatStart = width * beatRightPct;

    // Left Heartbeat Peak
    path.lineTo(leftBeatStart, centerY);
    path.lineTo(leftBeatStart + 8, centerY - 15);
    path.lineTo(leftBeatStart + 16, centerY + 25);
    path.lineTo(leftBeatStart + 28, centerY - 55);
    path.lineTo(leftBeatStart + 40, centerY + 35);
    path.lineTo(leftBeatStart + 48, centerY - 10);
    path.lineTo(leftBeatStart + 56, centerY);

    // Connecting straight segment
    path.lineTo(rightBeatStart, centerY);

    // Right Heartbeat Peak
    path.lineTo(rightBeatStart + 8, centerY - 15);
    path.lineTo(rightBeatStart + 16, centerY + 25);
    path.lineTo(rightBeatStart + 28, centerY - 55);
    path.lineTo(rightBeatStart + 40, centerY + 35);
    path.lineTo(rightBeatStart + 48, centerY - 10);
    path.lineTo(rightBeatStart + 56, centerY);

    path.lineTo(width, centerY);
    return path;
  }

  void _drawGlowSegment(Canvas canvas, Path path, double animVal) {
    final pathMetrics = path.computeMetrics();
    final iterator = pathMetrics.iterator;
    if (iterator.moveNext()) {
      final metric = iterator.current;
      final length = metric.length;

      const segmentLength = 70.0;
      final start = (length * animVal) - segmentLength;

      final extractPath = metric.extractPath(
        start.clamp(0.0, length),
        (start + segmentLength).clamp(0.0, length),
      );

      final glowPaint = Paint()
        ..color = const Color(0xFFE31837).withOpacity(0.95)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final corePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(extractPath, glowPaint);
      canvas.drawPath(extractPath, corePaint);
    }
  }

  @override
  bool shouldRepaint(HeartbeatBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
