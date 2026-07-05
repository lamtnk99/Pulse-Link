import 'package:flutter/material.dart';

/// Bảng màu và token dùng chung cho toàn phân hệ quyên góp.
///
/// Mục tiêu là giữ tông ấm, thấu cảm thay vì cảnh báo/y tế: sắc đỏ chủ đạo
/// được đặt cạnh hồng san hô và hổ phách để cảm giác dịu và gần gũi hơn.
class DonationPalette {
  const DonationPalette._();

  /// Đỏ chủ đạo (kế thừa brand Pulse Link).
  static const primary = Color(0xFFE31837);

  /// Hồng san hô phụ, dùng cho gradient ấm và điểm nhấn mềm.
  static const coral = Color(0xFFFF6B6B);

  /// Hổ phách ấm cho lời chúc / bảng vàng.
  static const amber = Color(0xFFFFB454);

  /// Vàng huy hiệu cho hạng 1.
  static const gold = Color(0xFFFFD700);
  static const silver = Color(0xFFC0C0C0);
  static const bronze = Color(0xFFCD7F32);

  /// Gradient ấm chủ đạo cho các mảng cảm xúc (hero, nút chính, celebration).
  static const warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFE31837)],
  );

  static Color surface(bool isDark) =>
      isDark ? const Color(0xFF1E293B) : Colors.white;

  static Color subtleBorder(bool isDark) => isDark
      ? Colors.white.withOpacity(0.06)
      : Colors.black.withOpacity(0.05);

  static Color mutedText(bool isDark) =>
      isDark ? Colors.white70 : Colors.black54;

  static Color strongText(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF0F172A);

  /// Màu + nhãn cho mức độ cấp thiết của chiến dịch.
  static ({Color color, String label, IconData icon})? urgency(String? level) {
    switch (level) {
      case 'critical':
        return (color: const Color(0xFFE31837), label: 'Rất cấp thiết', icon: Icons.priority_high_rounded);
      case 'urgent':
        return (color: const Color(0xFFFF8A3D), label: 'Cần gấp', icon: Icons.bolt_rounded);
      case 'normal':
        return (color: const Color(0xFF10B981), label: 'Đang kêu gọi', icon: Icons.favorite_rounded);
      default:
        return null;
    }
  }
}
