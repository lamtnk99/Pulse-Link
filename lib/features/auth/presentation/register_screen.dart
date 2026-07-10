import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/pulse_link_controller.dart';
import '../../shared/location_picker.dart';
import 'login_screen.dart' show HeartbeatBackgroundPainter;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.controller});

  final PulseLinkController controller;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _bloodType;
  String? _provinceCode;
  String? _wardCode;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _waveController;

  static const List<String> _bloodTypes = [
    'O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+',
  ];

  static const String _apiBaseUrl = String.fromEnvironment(
    'LARAVEL_API_BASE_URL',
    defaultValue: 'https://api.pulselink.asia',
  );

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/auth/register'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'password_confirmation': _confirmController.text,
          'phone': _phoneController.text.trim(),
          'blood_type': _bloodType,
          'province_code': _provinceCode,
          'ward_code': _wardCode,
        }),
      );

      final payload = jsonDecode(response.body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final message = payload['message'] ??
            payload['errors']?['email']?[0] ??
            'Đăng ký không thành công. Vui lòng thử lại.';
        throw Exception(message);
      }

      final token = payload['data']['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      // Đăng nhập luôn: nạp hồ sơ + kết nối realtime giống luồng login.
      await widget.controller.initialize();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D1A),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) => CustomPaint(
                painter: HeartbeatBackgroundPainter(
                  animationValue: _waveController.value,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'TẠO TÀI KHOẢN HIỆP SĨ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tham gia mạng lưới hiến máu cứu người',
                    style: TextStyle(
                      color: Color(0xFFE31837),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF091424).withOpacity(0.75),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1.2,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorMessage != null) ...[
                            _errorBox(_errorMessage!),
                            const SizedBox(height: 18),
                          ],
                          _fieldLabel('HỌ VÀ TÊN'),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _nameController,
                            hint: 'Nguyễn Văn A',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Vui lòng nhập họ tên'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          _fieldLabel('EMAIL'),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _emailController,
                            hint: 'email@domain.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Vui lòng nhập email';
                              }
                              if (!v.contains('@')) return 'Email không hợp lệ';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _fieldLabel('SỐ ĐIỆN THOẠI'),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _phoneController,
                            hint: '09xxxxxxxx',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),
                          _fieldLabel('NHÓM MÁU'),
                          const SizedBox(height: 8),
                          _bloodTypeDropdown(),
                          const SizedBox(height: 20),
                          LocationPicker(
                            apiBaseUrl: _apiBaseUrl,
                            provinceCode: _provinceCode,
                            wardCode: _wardCode,
                            onChanged: (p, w) {
                              setState(() {
                                _provinceCode = p;
                                _wardCode = w;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          _fieldLabel('MẬT KHẨU'),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _passwordController,
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Vui lòng nhập mật khẩu';
                              }
                              if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _fieldLabel('XÁC NHẬN MẬT KHẨU'),
                          const SizedBox(height: 8),
                          _textField(
                            controller: _confirmController,
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                            validator: (v) => v != _passwordController.text
                                ? 'Mật khẩu xác nhận không khớp'
                                : null,
                          ),
                          const SizedBox(height: 28),
                          _submitButton(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Đã có tài khoản? ',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Đăng nhập',
                            style: TextStyle(
                              color: Color(0xFFE31837),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF0F1B2C),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE31837), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _bloodTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2C),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _bloodType,
          hint: const Text('Chọn nhóm máu',
              style: TextStyle(color: Colors.white24, fontSize: 14)),
          dropdownColor: const Color(0xFF0F1B2C),
          iconEnabledColor: Colors.white38,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
          items: _bloodTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _bloodType = v),
        ),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE31837).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE31837).withOpacity(0.24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFE31837), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE31837), Color(0xFFB91C1C)],
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
          onTap: _isLoading ? null : _register,
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
                    'ĐĂNG KÝ',
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
    );
  }
}
