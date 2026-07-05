import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/pulse_link_theme.dart';

class HealthTrackerCard extends StatelessWidget {
  const HealthTrackerCard({
    super.key,
    required this.daysLeft,
    required this.progress,
    required this.nextEligibleDate,
  });

  final int daysLeft;
  final double progress;
  final DateTime nextEligibleDate;

  /// Lời động viên ấm áp thay đổi theo giai đoạn hồi phục — để đồng hồ đếm ngược
  /// trở thành sự quan tâm chứ không phải con số vô cảm.
  ({String title, String message, String tip}) _stageCopy() {
    if (daysLeft == 0) {
      return (
        title: 'Cơ thể bạn đã sẵn sàng',
        message: 'Bạn đã hồi phục trọn vẹn. Khi nào thấy sẵn lòng, một người nào đó ngoài kia đang chờ giọt máu của bạn.',
        tip: 'Nhớ ăn no và ngủ đủ trước ngày hiến nhé.',
      );
    }
    if (progress < 0.34) {
      return (
        title: 'Hãy nghỉ ngơi, bạn xứng đáng',
        message: 'Cơ thể bạn đang tái tạo lượng máu vừa cho đi. Những ngày này hãy nhẹ nhàng với chính mình.',
        tip: 'Uống nhiều nước ấm và tránh vận động gắng sức.',
      );
    }
    if (progress < 0.67) {
      return (
        title: 'Bạn đang hồi phục tốt',
        message: 'Đã đi được nửa chặng đường. Cơ thể bạn đang khỏe lại từng ngày.',
        tip: 'Bổ sung thực phẩm giàu sắt: thịt bò, rau lá xanh đậm.',
      );
    }
    return (
      title: 'Sắp sẵn sàng trở lại',
      message: 'Chỉ còn một chút nữa thôi. Cảm ơn bạn đã kiên nhẫn chăm sóc bản thân.',
      tip: 'Giữ giấc ngủ đều để cơ thể hoàn tất hồi phục.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final recoveredPercent = (progress * 100).round().clamp(0, 100);
    final copy = _stageCopy();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PulseLinkTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PulseLinkTheme.subtleBorderColor(context)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0).toDouble(),
                    strokeWidth: 7,
                    color: daysLeft == 0
                        ? PulseLinkTheme.successGreen
                        : PulseLinkTheme.primaryRed,
                    backgroundColor: PulseLinkTheme.subtleBorderColor(context),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$daysLeft',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: PulseLinkTheme.textColor(context),
                      ),
                    ),
                    Text(
                      'ngày',
                      style: TextStyle(
                        fontSize: 10,
                        color: PulseLinkTheme.mutedColor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: PulseLinkTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  copy.message,
                  style: TextStyle(
                    color: PulseLinkTheme.mutedColor(context),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                if (daysLeft > 0)
                  Text(
                    'Đủ điều kiện lại từ ${DateFormat('dd/MM/yyyy').format(nextEligibleDate)}.',
                    style: TextStyle(
                      color: PulseLinkTheme.mutedColor(context),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.monitor_heart_outlined,
                      color: PulseLinkTheme.successGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$recoveredPercent% hồi phục cơ thể',
                      style: const TextStyle(
                        color: PulseLinkTheme.successGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Mẹo chăm sóc theo giai đoạn — quan tâm ngược lại người hiến.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: PulseLinkTheme.primaryRed.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.tips_and_updates_outlined,
                        color: PulseLinkTheme.primaryRed,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          copy.tip,
                          style: TextStyle(
                            color: PulseLinkTheme.textColor(context).withOpacity(0.85),
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
