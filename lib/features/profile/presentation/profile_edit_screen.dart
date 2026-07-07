import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/pulse_link_controller.dart';
import '../../../core/theme/pulse_link_theme.dart';
import '../../shared/location_picker.dart';
import '../domain/donor_profile.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, required this.controller});

  final PulseLinkController controller;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _nationalIdController = TextEditingController();

  String? _bloodType;
  String? _gender;
  String? _dateOfBirth; // yyyy-MM-dd
  String? _provinceCode;
  String? _wardCode;
  String? _idFrontUrl;
  String? _idBackUrl;

  bool _saving = false;
  bool _uploadingFront = false;
  bool _uploadingBack = false;
  String? _errorMessage;

  static const List<String> _bloodTypes = [
    'O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+',
  ];

  static const String _apiBaseUrl = String.fromEnvironment(
    'LARAVEL_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  @override
  void initState() {
    super.initState();
    final p = widget.controller.state.profile;
    if (p != null) {
      _nameController.text = p.name;
      _phoneController.text = p.phone ?? '';
      _addressController.text = p.address ?? '';
      _nationalIdController.text = p.nationalId ?? '';
      _bloodType = p.bloodType.isEmpty ? null : p.bloodType;
      _gender = p.gender;
      _dateOfBirth = p.dateOfBirth;
      _provinceCode = p.provinceCode.isEmpty ? null : p.provinceCode;
      _wardCode = p.wardCode;
      _idFrontUrl = p.idCardFrontUrl;
      _idBackUrl = p.idCardBackUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload({required bool isFront}) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() {
      if (isFront) {
        _uploadingFront = true;
      } else {
        _uploadingBack = true;
      }
      _errorMessage = null;
    });

    try {
      final url = await widget.controller.uploadIdImage(file.path);
      setState(() {
        if (isFront) {
          _idFrontUrl = url;
        } else {
          _idBackUrl = url;
        }
      });
    } catch (_) {
      setState(() => _errorMessage = 'Không thể tải ảnh lên. Vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() {
          _uploadingFront = false;
          _uploadingBack = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await widget.controller.updateProfile({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'blood_type': _bloodType,
        'gender': _gender,
        'date_of_birth': _dateOfBirth,
        'address': _addressController.text.trim(),
        'province_code': _provinceCode,
        'ward_code': _wardCode,
        'national_id': _nationalIdController.text.trim().isEmpty
            ? null
            : _nationalIdController.text.trim(),
        'id_card_front_url': _idFrontUrl,
        'id_card_back_url': _idBackUrl,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật hồ sơ thành công.'),
            backgroundColor: PulseLinkTheme.successGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() => _errorMessage =
          'Không thể lưu hồ sơ: ${error.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = widget.controller.state.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật hồ sơ'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PulseLinkTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: PulseLinkTheme.primaryRed, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              color: PulseLinkTheme.primaryRed,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _sectionTitle('Thông tin cá nhân'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: _dec('Họ và tên', Icons.person_outline_rounded),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _dec('Số điện thoại', Icons.phone_outlined),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _bloodType,
              decoration: _dec('Nhóm máu', Icons.bloodtype_outlined),
              items: _bloodTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _bloodType = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: _dec('Giới tính', Icons.wc_outlined),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Nam')),
                DropdownMenuItem(value: 'female', child: Text('Nữ')),
                DropdownMenuItem(value: 'other', child: Text('Khác')),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 16),
            _dateField(context),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: _dec('Địa chỉ', Icons.home_outlined),
            ),
            const SizedBox(height: 16),
            LocationPicker(
              apiBaseUrl: _apiBaseUrl,
              provinceCode: _provinceCode,
              wardCode: _wardCode,
              dark: isDark,
              onChanged: (p, w) => setState(() {
                _provinceCode = p;
                _wardCode = w;
              }),
            ),
            const SizedBox(height: 28),
            _sectionTitle('Xác thực căn cước công dân'),
            const SizedBox(height: 6),
            if (profile != null) _verificationBadge(profile.idVerificationStatus),
            if (profile?.idVerificationStatus == 'rejected' &&
                (profile?.idRejectionReason ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Lý do từ chối: ${profile!.idRejectionReason}',
                style: const TextStyle(
                    color: PulseLinkTheme.primaryRed, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Thông tin người hiến cần chính xác. Nhập số CCCD và tải ảnh 2 mặt để quản trị viên xác thực.',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? PulseLinkTheme.mutedText
                      : PulseLinkTheme.mutedTextLight),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nationalIdController,
              keyboardType: TextInputType.number,
              maxLength: 12,
              decoration: _dec('Số CCCD (12 số)', Icons.badge_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // optional
                if (v.trim().length != 12) return 'Số CCCD phải đủ 12 chữ số';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _idImageSlot(
                    label: 'Mặt trước',
                    url: _idFrontUrl,
                    uploading: _uploadingFront,
                    onTap: () => _pickAndUpload(isFront: true),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _idImageSlot(
                    label: 'Mặt sau',
                    url: _idBackUrl,
                    uploading: _uploadingBack,
                    onTap: () => _pickAndUpload(isFront: false),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: PulseLinkTheme.primaryRed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Đang lưu...' : 'LƯU HỒ SƠ',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      );

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  Widget _dateField(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final now = DateTime.now();
        final initial = _dateOfBirth != null
            ? DateTime.tryParse(_dateOfBirth!) ?? DateTime(now.year - 20)
            : DateTime(now.year - 20);
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1940),
          lastDate: now,
        );
        if (picked != null) {
          setState(() => _dateOfBirth =
              '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
        }
      },
      child: InputDecorator(
        decoration: _dec('Ngày sinh', Icons.cake_outlined),
        child: Text(_dateOfBirth ?? 'Chọn ngày sinh',
            style: TextStyle(
                color: _dateOfBirth == null ? Colors.grey : null,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _verificationBadge(String status) {
    late final Color color;
    late final String label;
    late final IconData icon;
    switch (status) {
      case 'verified':
        color = PulseLinkTheme.successGreen;
        label = 'Đã xác thực';
        icon = Icons.verified_rounded;
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Đang chờ duyệt';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'rejected':
        color = PulseLinkTheme.primaryRed;
        label = 'Bị từ chối';
        icon = Icons.cancel_rounded;
        break;
      default:
        color = Colors.grey;
        label = 'Chưa xác thực';
        icon = Icons.info_outline_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _idImageSlot({
    required String label,
    required String? url,
    required bool uploading,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: uploading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B2747) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          ),
          image: url != null && !uploading
              ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
              : null,
        ),
        child: uploading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
            : (url == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, size: 26),
                      const SizedBox(height: 6),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  )
                : Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.black54,
                      child: Text(label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  )),
      ),
    );
  }
}
