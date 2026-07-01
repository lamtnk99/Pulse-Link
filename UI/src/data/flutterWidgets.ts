export interface FlutterWidgetDoc {
  name: string;
  category: string;
  description: string;
  flutterWidget: string;
  keyProperties: string[];
  dartCode: string;
}

export const FLUTTER_THEME_CODE = `// File: theme/pulse_link_theme.dart
import 'package:flutter/material.dart';

class PulseLinkTheme {
  static const Color primaryRed = Color(0xFFE31837);
  static const Color deepBloodRed = Color(0xFF9E0B20);
  static const Color darkBg = Color(0xFF121212);
  static const Color cardBg = Color(0xFF1E1E1E);
  static const Color textLight = Color(0xFFFAFAFA);
  static const Color textMuted = Color(0xFF9E9E9E);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBg,
      primaryColor: primaryRed,
      colorScheme: ColorScheme.dark(
        primary: primaryRed,
        secondary: deepBloodRed,
        surface: cardBg,
        background: darkBg,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: textLight,
        ),
      ),
    );
  }
}`;

export const FLUTTER_WIDGETS_DOCS: FlutterWidgetDoc[] = [
  {
    name: "Màn hình chính (Daily Mode)",
    category: "Page Structure",
    description: "Cấu trúc tổng quan của Trang chủ sử dụng Scaffold, BottomNavigationBar và SingleChildScrollView.",
    flutterWidget: "Scaffold & BottomNavigationBar",
    keyProperties: [
      "backgroundColor: PulseLinkTheme.darkBg",
      "bottomNavigationBar: ClipRRect(borderRadius: BorderRadius.vertical(...))",
      "body: SafeArea(child: SingleChildScrollView(...))"
    ],
    dartCode: `// File: screens/daily_mode_screen.dart
import 'package:flutter/material.dart';
import '../theme/pulse_link_theme.dart';
import '../widgets/hero_pass_card.dart';
import '../widgets/health_tracker.dart';
import '../widgets/event_card.dart';

class DailyModeScreen extends StatefulWidget {
  const DailyModeScreen({Key? key}) : super(key: key);

  @override
  State<DailyModeScreen> createState() => _DailyModeScreenState();
}

class _DailyModeScreenState extends State<DailyModeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(key) {
    return Scaffold(
      backgroundColor: PulseLinkTheme.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              const HeroPassCard(
                bloodType: 'O+',
                heroLevel: 'Silver Badge',
                totalDonations: 5,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Sự kiện hiến máu', 'Xem tất cả'),
              const SizedBox(height: 12),
              _buildUpcomingEventsList(),
              const SizedBox(height: 24),
              const Text(
                'Chỉ số sức khỏe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const HealthTrackerWidget(daysLeft: 14, progress: 0.84),
              const SizedBox(height: 80), // Padding cho bottom navigation bar
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào Hiệp sĩ,',
                  style: TextStyle(color: PulseLinkTheme.textMuted, fontSize: 13),
                ),
                const Text(
                  'Minh Trí 👋',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 26),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            action,
            style: const TextStyle(color: PulseLinkTheme.primaryRed, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEventsList() {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: const [
          EventCard(
            title: 'Chủ Nhật Đỏ - FPT Polytechnic',
            date: 'Chủ Nhật, 05/07/2026',
            location: 'Công viên phần mềm Quang Trung, Q.12',
            image: 'https://images.unsplash.com/photo-1615461066841-6116e61058f4',
          ),
          SizedBox(width: 12),
          EventCard(
            title: 'Giọt Hồng Nhân Ái - ĐH Bách Khoa',
            date: 'Thứ Ba, 07/07/2026',
            location: 'Sân B6 ĐH Bách Khoa, Q.10',
            image: 'https://images.unsplash.com/photo-1519491050282-cf00c82424b4',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: PulseLinkTheme.primaryRed,
        unselectedItemColor: PulseLinkTheme.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Sự kiện'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }
}`
  },
  {
    name: "Hero Pass Card",
    category: "Core Component",
    description: "Thẻ chứng nhận định danh Hiệp sĩ hiến máu với dải màu chuyển sắc gradient đỏ-đen cực kì cao cấp, hiển thị Nhóm máu, Cấp bậc hiệp sĩ và nút mở mã QR.",
    flutterWidget: "Container with BoxDecoration (Gradient)",
    keyProperties: [
      "gradient: LinearGradient(colors: [Color(0xFFE31837), Color(0xFF1E0306)], ...)",
      "borderRadius: BorderRadius.circular(24)",
      "boxShadow: [BoxShadow(color: Color(0xFFE31837).withOpacity(0.25), blurRadius: 20)]"
    ],
    dartCode: `// File: widgets/hero_pass_card.dart
import 'package:flutter/material.dart';
import '../theme/pulse_link_theme.dart';

class HeroPassCard extends StatelessWidget {
  final String bloodType;
  final String heroLevel;
  final int totalDonations;

  const HeroPassCard({
    Key? key,
    required this.bloodType,
    required this.heroLevel,
    required this.totalDonations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: PulseLinkTheme.primaryRed.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE31837), // Crimson Red
            Color(0xFF8A0012), // Deep Velvet Red
            Color(0xFF1A0003), // Jet Black Red shadow
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HERO PASS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Colors.white70,
                ),
              ),
              Image.asset('assets/images/logo_icon_white.png', height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.favorite, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nhóm máu', style: TextStyle(fontSize: 12, color: Colors.white60)),
                  Text(
                    bloodType,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(heroLevel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Đã hiến: $totalDonations lần', style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('MÃ SỐ ĐỊNH DANH', style: TextStyle(fontSize: 9, color: Colors.white50, letterSpacing: 1)),
                  Text('PL-8890-MINHTRI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Courier')),
                ],
              ),
              Material(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showQRModal(context),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: const [
                        Icon(Icons.qr_code, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Chứng nhận', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  void _showQRModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: PulseLinkTheme.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('CHỨNG NHẬN SỐ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white50)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.qr_code_2, size: 200, color: Colors.black),
            ),
            const SizedBox(height: 20),
            Text(heroLevel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PulseLinkTheme.primaryRed)),
            const SizedBox(height: 4),
            const Text('Hợp lệ tại tất cả các điểm hiến máu Việt Nam', style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}`
  },
  {
    name: "Upcoming Event Card",
    category: "Scrolling List Component",
    description: "Thành phần hiển thị thông tin sự kiện hiến máu, được thiết kế bo tròn tinh tế và tích hợp nút Đặt lịch thông minh.",
    flutterWidget: "Container with ClipRRect & Image.network",
    keyProperties: [
      "width: 260",
      "clipBehavior: Clip.antiAlias",
      "borderRadius: BorderRadius.circular(16)"
    ],
    dartCode: `// File: widgets/event_card.dart
import 'package:flutter/material.dart';
import '../theme/pulse_link_theme.dart';

class EventCard extends StatefulWidget {
  final String title;
  final String date;
  final String location;
  final String image;

  const EventCard({
    Key? key,
    required this.title,
    required this.date,
    required this.location,
    required this.image,
  }) : super(key: key);

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isBooked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                widget.image,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.white12, height: 100, child: const Icon(Icons.image)),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.location_on, color: PulseLinkTheme.primaryRed, size: 10),
                      SizedBox(width: 2),
                      Text('1.2 km', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 11, color: Colors.white60),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.date,
                        style: const TextStyle(fontSize: 10, color: Colors.white60),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Còn 42 chỗ', style: TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.w600)),
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: _isBooked ? Colors.grey[800] : PulseLinkTheme.primaryRed,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          setState(() {
                            _isBooked = !_isBooked;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isBooked ? 'Đã đặt lịch hiến máu thành công!' : 'Đã hủy lịch đăng ký.'),
                              backgroundColor: _isBooked ? Colors.green : Colors.red,
                            ),
                          );
                        },
                        child: Text(
                          _isBooked ? 'Đã đặt' : 'Đặt lịch',
                          style: TextStyle(
                            fontSize: 11, 
                            fontWeight: FontWeight.bold, 
                            color: _isBooked ? Colors.white50 : Colors.white
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}`
  },
  {
    name: "Health Tracker Widget",
    category: "Dashboard Widget",
    description: "Bộ đếm ngược thời gian thích hợp cho lần hiến máu tiếp theo. Sử dụng vòng tròn tiến trình (Circular Progress) để tạo điểm nhấn thị giác.",
    flutterWidget: "Card with Stack & CircularProgressIndicator",
    keyProperties: [
      "CircularProgressIndicator(value: 0.84, strokeWidth: 8, color: PulseLinkTheme.primaryRed)",
      "Card styling with deep grey background"
    ],
    dartCode: `// File: widgets/health_tracker.dart
import 'package:flutter/material.dart';
import '../theme/pulse_link_theme.dart';

class HealthTrackerWidget extends StatelessWidget {
  final int daysLeft;
  final double progress; // Giá trị từ 0.0 đến 1.0

  const HealthTrackerWidget({
    Key? key,
    required this.daysLeft,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: PulseLinkTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  color: PulseLinkTheme.primaryRed,
                  backgroundColor: Colors.white.withOpacity(0.08),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$daysLeft',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text('ngày', style: TextStyle(fontSize: 9, color: Colors.white50)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bạn đang hồi phục rất tốt!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cần thêm 14 ngày nữa để cơ thể đạt trạng thái huyết học lý tưởng nhất cho lần hiến máu tiếp theo.',
                  style: TextStyle(fontSize: 11, color: Colors.white60, height: 1.4),
                ),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 13),
                    SizedBox(width: 4),
                    Text('Lượng máu đã bù: 92%', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}`
  },
  {
    name: "Màn hình Khẩn cấp (SOS Mode)",
    category: "Page Structure",
    description: "Cấu trúc tổng quan của Màn hình Khẩn cấp SOS sử dụng Scaffold với background Gradient đỏ thẫm ấn tượng và các thành phần cảnh báo khẩn cấp.",
    flutterWidget: "Scaffold with Gradient Container",
    keyProperties: [
      "gradient: LinearGradient(colors: [Color(0xFF2B0408), Color(0xFF121212)])",
      "body: SafeArea(child: Padding(padding: 24, child: Column(...)))",
      "child elements: _buildSirenHeader(), LivingPulseWave(), HoldToCommitButton()"
    ],
    dartCode: `// File: screens/emergency_sos_screen.dart
import 'package:flutter/material.dart';
import '../widgets/living_pulse_wave.dart';
import '../widgets/hold_to_commit_button.dart';

class EmergencySosScreen extends StatelessWidget {
  const EmergencySosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2B0408), // Intense dark burgundy
              Color(0xFF121212), // Deep neutral black
            ],
            stops: [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                _buildSirenHeader(),
                const Spacer(),
                const LivingPulseWave(),
                const Spacer(),
                const HoldToCommitButton(secondsToHold: 3),
                const SizedBox(height: 20),
                _buildQuickInfoFooter(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSirenHeader() {
    return Column(
      children: [
        _buildPulsingSirenIcon(),
        const SizedBox(height: 16),
        const Text(
          'CỨU TRỢ KHẨN CẤP (SOS)',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.black,
            letterSpacing: 1.5,
            color: Color(0xFFFF334B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF334B).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF334B).withOpacity(0.2)),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFFFAFAFA),
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'Bệnh viện Đa khoa X ', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: 'đang báo động đỏ thiếu nhóm máu '),
                TextSpan(
                  text: 'O+ của bạn ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF334B)),
                ),
                TextSpan(text: 'trong bán kính '),
                TextSpan(text: '5km', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPulsingSirenIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFF334B).withOpacity(0.15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF334B).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.notifications_active_rounded,
          color: Color(0xFFFF334B),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildQuickInfoFooter() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        'Sau khi cam kết, mạch sống của bạn sẽ kết nối với bệnh viện và lộ trình di chuyển nhanh nhất sẽ được kích hoạt',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: Color(0xFF9E9E9E),
          height: 1.4,
        ),
      ),
    );
  }
}`
  },
  {
    name: "Sóng nhịp tim (Living Pulse Wave)",
    category: "Interactive Canvas Component",
    description: "Một dải sóng đồ thị điện tim (ECG) mô phỏng nhịp đập của trái tim (Living Pulse) nhấp nháy đỏ theo chu kỳ nhịp đập yếu.",
    flutterWidget: "AnimatedBuilder with CustomPainter",
    keyProperties: [
      "CustomPaint(painter: PulseWavePainter(...))",
      "AnimationController(duration: Duration(milliseconds: 2400))",
      "Canvas.drawPath(path, Paint()..style = PaintingStyle.stroke)"
    ],
    dartCode: `// File: widgets/living_pulse_wave.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class LivingPulseWave extends StatefulWidget {
  const LivingPulseWave({Key? key}) : super(key: key);

  @override
  State<LivingPulseWave> createState() => _LivingPulseWaveState();
}

class _LivingPulseWaveState extends State<LivingPulseWave> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: PulseWavePainter(
              animationValue: _controller.value,
              color: const Color(0xFFFF334B),
            ),
          );
        },
      ),
    );
  }
}

class PulseWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  PulseWavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    path.moveTo(0, centerY);

    for (double x = 0; x <= width; x += 1) {
      double t = x / width;
      double distance = (t - animationValue).abs();
      if (distance > 0.5) distance = 1.0 - distance;
      
      double envelope = math.exp(-math.pow(distance * 8, 2)); 
      double waveY = 0;
      
      if (distance < 0.15) {
        waveY = math.sin(distance * 2 * math.pi * 5) * 40 * envelope;
        if (distance < 0.05) {
          waveY = -math.sin(distance * math.pi * 10) * 50 * envelope; 
        }
      } else if (distance < 0.3) {
        waveY = math.sin(distance * math.pi * 4) * 15 * envelope;
      }
      
      double y = centerY + waveY;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Active pulse core dot
    final pulseX = width * animationValue;
    canvas.drawCircle(Offset(pulseX, centerY), 8, Paint()..color = color.withOpacity(0.3));
    canvas.drawCircle(Offset(pulseX, centerY), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant PulseWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}`
  },
  {
    name: "Nút Cam kết 3s (Hold to Commit Button)",
    category: "Interactive Hero Action",
    description: "Nút bấm thông minh khổng lồ, phát sáng viền neon-đỏ. Người dùng nhấn giữ liên tục trong 3 giây để xác lập cam kết hiến máu khẩn cấp.",
    flutterWidget: "GestureDetector with AnimationController & CircularProgress",
    keyProperties: [
      "GestureDetector(onTapDown: ..., onTapUp: ..., onTapCancel: ...)",
      "CircularProgressIndicator(value: animationController.value, ...)",
      "AnimatedContainer(duration: 150ms, decoration: BoxDecoration(shape: BoxShape.circle))"
    ],
    dartCode: `// File: widgets/hold_to_commit_button.dart
import 'package:flutter/material.dart';

class HoldToCommitButton extends StatefulWidget {
  final int secondsToHold;
  const HoldToCommitButton({Key? key, this.secondsToHold = 3}) : super(key: key);

  @override
  State<HoldToCommitButton> createState() => _HoldToCommitButtonState();
}

class _HoldToCommitButtonState extends State<HoldToCommitButton> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.secondsToHold),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isSuccess = true);
        _triggerSuccessFeedback();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _triggerSuccessFeedback() {
    // HapticFeedback.vibrate();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => !_isSuccess ? _progressController.forward() : null,
      onTapUp: (_) => !_isSuccess ? _progressController.reverse() : null,
      onTapCancel: () => !_isSuccess ? _progressController.reverse() : null,
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          double val = _progressController.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: val,
                  strokeWidth: 6,
                  color: const Color(0xFFFF334B),
                  backgroundColor: Colors.white.withOpacity(0.05),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isSuccess ? const Color(0xFF00C853) : const Color(0xFF2B0408),
                  border: Border.all(
                    color: _isSuccess ? const Color(0xFF00C853) : const Color(0xFFFF334B),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isSuccess 
                          ? const Color(0xFF00C853).withOpacity(0.4)
                          : const Color(0xFFFF334B).withOpacity(0.3 + val * 0.4),
                      blurRadius: 20 + val * 25,
                      spreadRadius: 2 + val * 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle_rounded : Icons.fingerprint_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSuccess ? 'ĐÃ CAM KẾT' : 'NHẤN GIỮ 3S',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.black, color: Colors.white),
                      ),
                      if (!_isSuccess) ...[
                        const SizedBox(height: 2),
                        const Text('ĐỂ CAM KẾT', style: TextStyle(fontSize: 9, color: Colors.white70)),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}`
  }
];

