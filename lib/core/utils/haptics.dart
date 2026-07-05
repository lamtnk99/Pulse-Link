import 'package:flutter/services.dart';

/// Trung tâm hóa các rung phản hồi (haptic) để trải nghiệm "chạm được".
///
/// Gom về một chỗ để dễ điều chỉnh cường độ và, sau này, tôn trọng tùy chọn
/// "giảm rung" của người dùng nếu cần. Mọi lời gọi đều bọc try/catch ngầm qua
/// nền tảng nên an toàn trên web/desktop (nơi haptic có thể không khả dụng).
class Haptics {
  const Haptics._();

  /// Chạm nhẹ khi bắt đầu một thao tác (ví dụ: bắt đầu giữ nút).
  static void tap() => HapticFeedback.selectionClick();

  /// Một "nhịp tim" nhẹ — dùng khi giữ nút xác nhận để tạo cảm giác đồng nhịp.
  static void heartbeat() => HapticFeedback.lightImpact();

  /// Phản hồi mốc trung gian (ví dụ vượt 50% tiến trình giữ).
  static void milestone() => HapticFeedback.mediumImpact();

  /// Khoảnh khắc thành công lớn (cam kết SOS, lên cấp Hero, hoàn tất quyên góp).
  static void success() => HapticFeedback.heavyImpact();

  /// Báo lỗi / hủy nhẹ nhàng.
  static void warn() => HapticFeedback.mediumImpact();
}
