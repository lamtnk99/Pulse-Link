import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Một tỉnh/thành hoặc phường/xã lấy từ location master data.
class LocationOption {
  const LocationOption({required this.code, required this.fullName});

  factory LocationOption.fromJson(Map<String, dynamic> json) {
    return LocationOption(
      code: json['code'] as String,
      fullName: (json['full_name'] ?? json['name'] ?? '') as String,
    );
  }

  final String code;
  final String fullName;
}

/// Bộ chọn Tỉnh/thành + Phường/xã liên động, dùng chung cho màn đăng ký và
/// cập nhật hồ sơ. Gọi các endpoint công khai /api/locations/*.
class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    required this.apiBaseUrl,
    required this.provinceCode,
    required this.wardCode,
    required this.onChanged,
    this.dark = true,
  });

  final String apiBaseUrl;
  final String? provinceCode;
  final String? wardCode;

  /// Trả về (provinceCode, wardCode) mỗi khi người dùng đổi lựa chọn.
  final void Function(String? provinceCode, String? wardCode) onChanged;

  /// Kiểu tối (dùng trên nền đăng nhập) hay sáng (màn hồ sơ).
  final bool dark;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  List<LocationOption> _provinces = [];
  List<LocationOption> _wards = [];
  String? _provinceCode;
  String? _wardCode;
  bool _loadingProvinces = false;
  bool _loadingWards = false;

  @override
  void initState() {
    super.initState();
    _provinceCode = widget.provinceCode;
    _wardCode = widget.wardCode;
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    setState(() => _loadingProvinces = true);
    try {
      final res = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/locations/provinces'),
        headers: {'Accept': 'application/json'},
      );
      final decoded = jsonDecode(res.body);
      final list = (decoded['data'] as List<dynamic>? ?? decoded as List<dynamic>);
      _provinces = list
          .map((e) => LocationOption.fromJson(e as Map<String, dynamic>))
          .toList();
      if (_provinceCode != null) {
        await _loadWards(_provinceCode!);
      }
    } catch (_) {
      // Im lặng — dropdown rỗng nếu không tải được; người dùng có thể thử lại.
    } finally {
      if (mounted) setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _loadWards(String provinceCode) async {
    setState(() => _loadingWards = true);
    try {
      final res = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/locations/provinces/$provinceCode/wards'),
        headers: {'Accept': 'application/json'},
      );
      final decoded = jsonDecode(res.body);
      final list = (decoded['data'] as List<dynamic>? ?? decoded as List<dynamic>);
      _wards = list
          .map((e) => LocationOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _wards = [];
    } finally {
      if (mounted) setState(() => _loadingWards = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('TỈNH / THÀNH PHỐ'),
        const SizedBox(height: 8),
        _dropdown(
          hint: _loadingProvinces ? 'Đang tải...' : 'Chọn tỉnh/thành',
          value: _provinceCode,
          items: _provinces,
          onChanged: (code) {
            setState(() {
              _provinceCode = code;
              _wardCode = null;
              _wards = [];
            });
            widget.onChanged(code, null);
            if (code != null) _loadWards(code);
          },
        ),
        const SizedBox(height: 16),
        _label('PHƯỜNG / XÃ'),
        const SizedBox(height: 8),
        _dropdown(
          hint: _loadingWards
              ? 'Đang tải...'
              : (_provinceCode == null ? 'Chọn tỉnh/thành trước' : 'Chọn phường/xã'),
          value: _wardCode,
          items: _wards,
          onChanged: (code) {
            setState(() => _wardCode = code);
            widget.onChanged(_provinceCode, code);
          },
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: widget.dark ? Colors.white54 : Colors.black54,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _dropdown({
    required String hint,
    required String? value,
    required List<LocationOption> items,
    required ValueChanged<String?> onChanged,
  }) {
    final fill = widget.dark ? const Color(0xFF0F1B2C) : const Color(0xFFF1F5F9);
    final textColor = widget.dark ? Colors.white : Colors.black87;
    final hasValue = value != null && items.any((e) => e.code == value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: hasValue ? value : null,
          hint: Text(
            hint,
            style: TextStyle(color: textColor.withOpacity(0.4), fontSize: 14),
          ),
          dropdownColor: fill,
          iconEnabledColor: textColor.withOpacity(0.6),
          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e.code,
                    child: Text(e.fullName, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
