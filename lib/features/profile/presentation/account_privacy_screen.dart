import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/pulse_link_bootstrap.dart';
import '../../../app/pulse_link_controller.dart';
import '../../../core/theme/pulse_link_theme.dart';

class AccountPrivacyScreen extends StatefulWidget {
  const AccountPrivacyScreen({super.key, required this.controller});

  final PulseLinkController controller;

  @override
  State<AccountPrivacyScreen> createState() => _AccountPrivacyScreenState();
}

class _AccountPrivacyScreenState extends State<AccountPrivacyScreen> {
  static const _confirmationText = 'XÓA TÀI KHOẢN';

  bool _deleting = false;

  Uri _webUri(String path) {
    final apiBase = Uri.parse(PulseLinkBootstrap.laravelBaseUrl);
    return apiBase.replace(path: path, query: null, fragment: null);
  }

  Future<void> _openPolicy(String path) async {
    final uri = _webUri(path);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không mở được $uri')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmationController = TextEditingController();
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_deleting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canDelete =
                confirmationController.text.trim() == _confirmationText;
            return AlertDialog(
              title: const Text('Xóa tài khoản?'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tài khoản, token đăng nhập, thông báo, chat, vị trí và dữ liệu định danh/CCCD sẽ bị xóa. Lịch sử cần đối soát y tế được giữ ở dạng ẩn danh.',
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Lý do (không bắt buộc)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmationController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Nhập XÓA TÀI KHOẢN để xác nhận',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _deleting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: !_deleting && canDelete
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: PulseLinkTheme.primaryRed,
                  ),
                  child: const Text('Xóa tài khoản'),
                ),
              ],
            );
          },
        );
      },
    );

    final reason = reasonController.text;
    confirmationController.dispose();
    reasonController.dispose();

    if (confirmed == true) {
      await _deleteAccount(reason);
    }
  }

  Future<void> _deleteAccount(String reason) async {
    setState(() => _deleting = true);
    try {
      await widget.controller.deleteAccount(
        confirmation: _confirmationText,
        reason: reason,
      );
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chưa xóa được tài khoản: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PulseLinkTheme.isDark(context);
    final surface = PulseLinkTheme.surfaceColor(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản & quyền riêng tư'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _PrivacyHero(surface: surface, isDark: isDark),
          const SizedBox(height: 14),
          _PrivacyTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Chính sách quyền riêng tư',
            subtitle:
                'Dữ liệu thu thập, mục đích sử dụng, bên thứ ba và cách xóa dữ liệu.',
            onTap: () => _openPolicy('/legal/privacy'),
          ),
          _PrivacyTile(
            icon: Icons.description_outlined,
            title: 'Điều khoản sử dụng',
            subtitle:
                'Vai trò nền tảng, cảnh báo y tế và trách nhiệm người dùng.',
            onTap: () => _openPolicy('/legal/terms'),
          ),
          _PrivacyTile(
            icon: Icons.support_agent_outlined,
            title: 'Hỗ trợ',
            subtitle: 'Kênh liên hệ cho người hiến, bệnh viện và App Review.',
            onTap: () => _openPolicy('/support'),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF231316) : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: PulseLinkTheme.primaryRed.withOpacity(0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.delete_forever_outlined,
                      color: PulseLinkTheme.primaryRed,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Xóa tài khoản',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Thao tác này xóa tài khoản và dữ liệu định danh. Những bản ghi cần giữ để đối soát y tế/thống kê sẽ được ẩn danh.',
                  style: TextStyle(
                    height: 1.45,
                    color: isDark ? Colors.white70 : PulseLinkTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _deleting ? null : _confirmDelete,
                    icon: _deleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline_rounded),
                    label: Text(_deleting ? 'Đang xóa...' : 'Xóa tài khoản'),
                    style: FilledButton.styleFrom(
                      backgroundColor: PulseLinkTheme.primaryRed,
                    ),
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

class _PrivacyHero extends StatelessWidget {
  const _PrivacyHero({
    required this.surface,
    required this.isDark,
  });

  final Color surface;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PulseLinkTheme.subtleBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: PulseLinkTheme.primaryRed.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: PulseLinkTheme.primaryRed,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bạn kiểm soát dữ liệu của mình',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pulse Link chỉ dùng dữ liệu để điều phối hiến máu, chăm sóc và vận hành an toàn.',
                  style: TextStyle(
                    height: 1.4,
                    color: isDark ? Colors.white70 : PulseLinkTheme.mutedText,
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

class _PrivacyTile extends StatelessWidget {
  const _PrivacyTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: PulseLinkTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: PulseLinkTheme.subtleBorderColor(context),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: PulseLinkTheme.primaryRed),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: PulseLinkTheme.mutedColor(context),
                          height: 1.35,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
