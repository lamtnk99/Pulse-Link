import 'package:flutter/material.dart';

import '../../../app/pulse_link_controller.dart';
import '../../../core/theme/pulse_link_theme.dart';
import '../domain/notification_preferences.dart';
import '../../../infrastructure/notifications/mobile_push_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, required this.controller});

  final PulseLinkController controller;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationPreferences _preferences = const NotificationPreferences();
  bool _loading = true;
  bool _saving = false;
  bool _testingPush = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preferences = await widget.controller.getNotificationPreferences();
      if (mounted) setState(() => _preferences = preferences);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chưa tải được cài đặt thông báo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(NotificationPreferences preferences) async {
    setState(() => _saving = true);
    try {
      final saved =
          await widget.controller.updateNotificationPreferences(preferences);
      if (mounted) setState(() => _preferences = saved);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chưa lưu được cài đặt: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _requestPermission() async {
    final status = await widget.controller.requestPushPermission();
    if (!mounted) return;
    final message = switch (status) {
      PushPermissionStatus.granted => 'Đã bật thông báo trên thiết bị.',
      PushPermissionStatus.denied =>
        'Bạn có thể bật lại quyền thông báo trong phần Cài đặt của thiết bị.',
      PushPermissionStatus.unavailable =>
        'Firebase push chưa được cấu hình cho bản ứng dụng này.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _testPush() async {
    setState(() => _testingPush = true);
    try {
      final message = await widget.controller.sendTestPushNotification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error
          .toString()
          .replaceFirst('Bad state: ', '')
          .replaceFirst('StateError: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _testingPush = false);
    }
  }

  Future<void> _pickQuietHours() async {
    final start = await showTimePicker(
      context: context,
      initialTime: _timeOfDay(_preferences.quietHoursStart) ??
          const TimeOfDay(hour: 22, minute: 0),
      helpText: 'Bắt đầu giờ yên lặng',
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: _timeOfDay(_preferences.quietHoursEnd) ??
          const TimeOfDay(hour: 7, minute: 0),
      helpText: 'Kết thúc giờ yên lặng',
    );
    if (end == null) return;
    await _save(
      _preferences.copyWith(
        quietHoursStart: _formatTime(start),
        quietHoursEnd: _formatTime(end),
      ),
    );
  }

  TimeOfDay? _timeOfDay(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = PulseLinkTheme.isDark(context);
    final muted = PulseLinkTheme.mutedColor(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                const Text(
                  'NHẬN TIN ĐÚNG LÚC',
                  style: TextStyle(
                    color: PulseLinkTheme.primaryRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn luôn quyết định loại thông báo Pulse Link được phép gửi. SOS chỉ được gửi khi hồ sơ phù hợp với ca khẩn.',
                  style: TextStyle(color: muted, height: 1.45),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _requestPermission,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Bật thông báo trên thiết bị'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _testingPush ? null : _testPush,
                  icon: _testingPush
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_to_mobile_outlined),
                  label: Text(
                    _testingPush
                        ? 'Đang kiểm tra kết nối Firebase...'
                        : 'Gửi thông báo thử',
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionTitle('CA KHẨN VÀ LỊCH HIẾN'),
                _SettingSwitch(
                  icon: Icons.emergency_outlined,
                  title: 'SOS phù hợp',
                  subtitle: 'Cảnh báo khẩn từ bệnh viện khi bạn đủ điều kiện.',
                  value: _preferences.sosEnabled,
                  enabled: !_saving,
                  onChanged: (value) =>
                      _save(_preferences.copyWith(sosEnabled: value)),
                ),
                _SettingSwitch(
                  icon: Icons.event_available_outlined,
                  title: 'Lịch đã đăng ký',
                  subtitle:
                      'Xác nhận, nhắc trước lịch và thay đổi từ bệnh viện.',
                  value: _preferences.appointmentsEnabled,
                  enabled: !_saving,
                  onChanged: (value) =>
                      _save(_preferences.copyWith(appointmentsEnabled: value)),
                ),
                const SizedBox(height: 20),
                const _SectionTitle('CHĂM SÓC VÀ CỘNG ĐỒNG'),
                _SettingSwitch(
                  icon: Icons.favorite_border_rounded,
                  title: 'Chăm sóc sau hiến',
                  subtitle: 'Lời cảm ơn, hành trình giọt máu và nhắc chăm sóc.',
                  value: _preferences.careEnabled,
                  enabled: !_saving,
                  onChanged: (value) =>
                      _save(_preferences.copyWith(careEnabled: value)),
                ),
                _SettingSwitch(
                  icon: Icons.location_on_outlined,
                  title: 'Lịch hiến gần bạn',
                  subtitle:
                      'Gợi ý nhẹ khi có lịch mới phù hợp khu vực của bạn.',
                  value: _preferences.nearbyEventsEnabled,
                  enabled: !_saving,
                  onChanged: (value) => _save(
                    _preferences.copyWith(nearbyEventsEnabled: value),
                  ),
                ),
                _SettingSwitch(
                  icon: Icons.groups_2_outlined,
                  title: 'Cộng đồng và chiến dịch',
                  subtitle: 'Cập nhật hoạt động bạn đã theo dõi.',
                  value: _preferences.communityEnabled,
                  enabled: !_saving,
                  onChanged: (value) =>
                      _save(_preferences.copyWith(communityEnabled: value)),
                ),
                const SizedBox(height: 20),
                const _SectionTitle('GIỜ YÊN LẶNG'),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.bedtime_outlined),
                  title: const Text(
                    'Tạm dừng thông báo thường',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    _preferences.quietHoursStart == null
                        ? 'SOS vẫn được ưu tiên. Chưa thiết lập giờ yên lặng.'
                        : '${_preferences.quietHoursStart} - ${_preferences.quietHoursEnd} · SOS vẫn được ưu tiên.',
                    style: TextStyle(color: muted),
                  ),
                  trailing: IconButton(
                    tooltip: 'Chọn giờ yên lặng',
                    onPressed: _saving ? null : _pickQuietHours,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
                if (_preferences.quietHoursStart != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _save(
                                _preferences.copyWith(clearQuietHours: true),
                              ),
                      icon: const Icon(Icons.timer_off_outlined),
                      label: const Text('Tắt giờ yên lặng'),
                    ),
                  ),
                if (isDark) const SizedBox(height: 4),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: PulseLinkTheme.mutedColor(context),
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(
        subtitle,
        style:
            TextStyle(color: PulseLinkTheme.mutedColor(context), height: 1.3),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}
