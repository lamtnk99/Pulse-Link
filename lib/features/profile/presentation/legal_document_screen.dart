import 'package:flutter/material.dart';

import '../../../core/theme/pulse_link_theme.dart';

enum LegalDocumentType { privacy, terms, support }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.type});

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final document = _LegalDocument.forType(type);
    final isDark = PulseLinkTheme.isDark(context);

    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: PulseLinkTheme.primaryRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(document.icon, color: PulseLinkTheme.primaryRed),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      document.summary,
                      style: TextStyle(
                        height: 1.45,
                        color:
                            isDark ? Colors.white70 : PulseLinkTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Cập nhật ngày 10 tháng 7 năm 2026',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : PulseLinkTheme.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          for (final section in document.sections) ...[
            _LegalSection(section: section),
            const Divider(height: 32),
          ],
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.section});

  final _LegalSectionData section;

  @override
  Widget build(BuildContext context) {
    final isDark = PulseLinkTheme.isDark(context);
    final textColor = isDark ? Colors.white70 : PulseLinkTheme.mutedText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        if (section.body != null)
          Text(section.body!, style: TextStyle(height: 1.5, color: textColor)),
        for (final item in section.items) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.circle,
                    size: 5, color: PulseLinkTheme.primaryRed),
              ),
              const SizedBox(width: 10),
              Expanded(
                child:
                    Text(item, style: TextStyle(height: 1.5, color: textColor)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LegalDocument {
  const _LegalDocument({
    required this.title,
    required this.summary,
    required this.icon,
    required this.sections,
  });

  final String title;
  final String summary;
  final IconData icon;
  final List<_LegalSectionData> sections;

  static _LegalDocument forType(LegalDocumentType type) {
    switch (type) {
      case LegalDocumentType.privacy:
        return const _LegalDocument(
          title: 'Chính sách quyền riêng tư',
          summary:
              'Pulse Link bảo vệ dữ liệu cá nhân để điều phối hiến máu an toàn và minh bạch.',
          icon: Icons.privacy_tip_outlined,
          sections: [
            _LegalSectionData(
              title: 'Dữ liệu chúng tôi thu thập',
              items: [
                'Thông tin hồ sơ như họ tên, số điện thoại, email, địa chỉ, nhóm máu và lịch sử hiến máu.',
                'Thông tin xác minh danh tính gồm số CCCD và ảnh giấy tờ khi bạn lựa chọn xác minh.',
                'Vị trí khi bạn cho phép, nội dung trò chuyện, thông báo thiết bị và nhật ký kỹ thuật cần thiết.',
              ],
            ),
            _LegalSectionData(
              title: 'Mục đích sử dụng',
              items: [
                'Xác thực người hiến, quản lý lịch hẹn và lịch sử hiến máu.',
                'Ghép nối yêu cầu máu khẩn cấp theo nhóm máu, vị trí và khả năng phản hồi.',
                'Gửi thông báo, chăm sóc sau hiến, cải thiện độ an toàn và xử lý sự cố kỹ thuật.',
              ],
            ),
            _LegalSectionData(
              title: 'Chia sẻ và bảo vệ dữ liệu',
              body:
                  'Chúng tôi chỉ chia sẻ dữ liệu cần thiết với bệnh viện, đơn vị vận hành và nhà cung cấp hạ tầng để thực hiện dịch vụ. Pulse Link không bán dữ liệu cá nhân.',
            ),
            _LegalSectionData(
              title: 'Lưu giữ và xóa dữ liệu',
              body:
                  'Bạn có thể xóa tài khoản tại màn hình Tài khoản & quyền riêng tư. Dữ liệu định danh, token, thông báo, vị trí, trò chuyện và ảnh CCCD sẽ bị xóa. Bản ghi cần đối soát y tế hoặc thống kê được giữ ở dạng ẩn danh, không còn liên kết với tài khoản của bạn.',
            ),
            _LegalSectionData(
              title: 'Quyền của bạn',
              items: [
                'Xem và cập nhật thông tin hồ sơ.',
                'Từ chối quyền vị trí và vẫn chọn địa chỉ thủ công.',
                'Yêu cầu hỗ trợ về dữ liệu qua mục Hỗ trợ.',
              ],
            ),
          ],
        );
      case LegalDocumentType.terms:
        return const _LegalDocument(
          title: 'Điều khoản sử dụng',
          summary:
              'Điều khoản quy định cách sử dụng Pulse Link một cách an toàn, tôn trọng và đúng mục đích.',
          icon: Icons.description_outlined,
          sections: [
            _LegalSectionData(
              title: 'Vai trò của Pulse Link',
              body:
                  'Pulse Link là nền tảng hỗ trợ điều phối hiến máu, cung cấp thông tin và kết nối phản hồi trong tình huống khẩn cấp. Nền tảng không thay thế chẩn đoán, điều trị hay quyết định chuyên môn của cơ sở y tế.',
            ),
            _LegalSectionData(
              title: 'An toàn y tế',
              items: [
                'Trong trường hợp khẩn cấp, hãy liên hệ bệnh viện hoặc dịch vụ cấp cứu phù hợp.',
                'Mọi quyết định sàng lọc, hiến máu và truyền máu phải do nhân viên y tế có thẩm quyền thực hiện.',
                'Nội dung do AI cung cấp chỉ mang tính hỗ trợ thông tin, không phải chẩn đoán hay chỉ định y khoa.',
              ],
            ),
            _LegalSectionData(
              title: 'Trách nhiệm người dùng',
              items: [
                'Cung cấp thông tin chính xác, không mạo danh người khác.',
                'Chỉ phản hồi SOS khi có khả năng tham gia và tuân thủ hướng dẫn của bệnh viện.',
                'Không đăng nội dung gây hiểu nhầm, quấy rối hoặc tiết lộ dữ liệu riêng tư.',
              ],
            ),
            _LegalSectionData(
              title: 'Tài khoản và thay đổi điều khoản',
              body:
                  'Chúng tôi có thể hạn chế quyền truy cập khi phát hiện hành vi vi phạm an toàn, pháp luật hoặc điều khoản này. Khi nội dung thay đổi quan trọng, Pulse Link sẽ cập nhật ngày hiệu lực và thông báo trong ứng dụng khi phù hợp.',
            ),
          ],
        );
      case LegalDocumentType.support:
        return const _LegalDocument(
          title: 'Hỗ trợ',
          summary:
              'Kênh tiếp nhận hỗ trợ cho người hiến, bệnh viện và các yêu cầu về tài khoản hoặc dữ liệu.',
          icon: Icons.support_agent_outlined,
          sections: [
            _LegalSectionData(
              title: 'Tài khoản và dữ liệu',
              body:
                  'Gửi yêu cầu đến support@pulselink.asia, kèm email hoặc số điện thoại đã đăng ký và mô tả ngắn về vấn đề. Không gửi ảnh CCCD hoặc thông tin sức khỏe nhạy cảm qua email công khai nếu chưa được hướng dẫn.',
            ),
            _LegalSectionData(
              title: 'Điều phối hiến máu',
              body:
                  'Để xác nhận lịch hiến, thông tin bệnh viện hoặc phản hồi SOS, hãy liên hệ điều phối viên hoặc bệnh viện hiển thị trong sự kiện. Trong tình huống khẩn cấp, ưu tiên gọi bệnh viện hoặc dịch vụ cấp cứu.',
            ),
            _LegalSectionData(
              title: 'Xóa tài khoản',
              body:
                  'Bạn có thể xóa tài khoản trực tiếp tại màn hình trước đó bằng cách chọn Xóa tài khoản và nhập cụm từ xác nhận. Sau khi hoàn tất, bạn sẽ được đăng xuất khỏi thiết bị.',
            ),
          ],
        );
    }
  }
}

class _LegalSectionData {
  const _LegalSectionData({
    required this.title,
    this.body,
    this.items = const [],
  });

  final String title;
  final String? body;
  final List<String> items;
}
