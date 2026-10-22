import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'student_list_screen.dart';
import 'login_screen.dart';
import 'attendance_qr_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  UserModel? _currentUser;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getSavedUser();
    setState(() => _currentUser = user);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ở lại')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Future<void> _showCreateSessionDialog() async {
    final randomCode = (Random().nextInt(900000) + 100000).toString();
    final titleController = TextEditingController(text: 'Lập trình ứng dụng di động');
    final sessionCodeController = TextEditingController(text: randomCode);
    final durationController = TextEditingController(text: '30');
    final radiusController = TextEditingController(text: '200');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          content: Container(
            width: double.maxFinite,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tạo phiên điểm danh', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                            Text('QR động + Mã 6 số', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                // Dialog body
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _dialogField(
                        controller: titleController,
                        label: 'Tên buổi học *',
                        icon: Icons.school_rounded,
                      ),
                      const SizedBox(height: 14),
                      _dialogField(
                        controller: sessionCodeController,
                        label: 'Mã phiên (6 số) *',
                        icon: Icons.tag_rounded,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                          onPressed: () {
                            sessionCodeController.text = (Random().nextInt(900000) + 100000).toString();
                            HapticFeedback.selectionClick();
                          },
                          tooltip: 'Tạo mã mới',
                        ),
                        helperText: 'Sinh viên nhập thủ công nếu không quét được QR',
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _dialogField(
                              controller: durationController,
                              label: 'Thời gian (phút)',
                              icon: Icons.timer_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dialogField(
                              controller: radiusController,
                              label: 'Bán kính GPS (m)',
                              icon: Icons.location_on_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Dialog actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: const BorderSide(color: AppTheme.border, width: 1.5),
                          ),
                          child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppTheme.primaryLight, AppTheme.primary]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 12, offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                final title = titleController.text.trim();
                                final code = sessionCodeController.text.trim();
                                final duration = int.tryParse(durationController.text.trim()) ?? 30;
                                final radius = int.tryParse(radiusController.text.trim()) ?? 200;

                                if (title.isEmpty || code.isEmpty || code.length != 6) {
                                  return;
                                }

                                Navigator.pop(ctx);

                                _showLoadingSnackBar('Đang khởi tạo phiên điểm danh...');

                                try {
                                  final token = await AuthService.getToken();
                                  final response = await http.post(
                                    Uri.parse(ApiConfig.attendanceSession),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      if (token != null) 'Authorization': 'Bearer $token',
                                    },
                                    body: jsonEncode({
                                      'courseId': 1,
                                      'title': title,
                                      'sessionCode': code,
                                      'durationMinutes': duration,
                                      'latitude': 10.8231,
                                      'longitude': 106.6297,
                                      'allowedRadiusMeters': radius,
                                    }),
                                  );

                                  if (!mounted) return;
                                  final data = jsonDecode(utf8.decode(response.bodyBytes));
                                  if (response.statusCode == 200 && data['success'] == true) {
                                    HapticFeedback.mediumImpact();
                                    final sessionObj = data['session'] ?? data['data'];
                                    final dynamic rawId = sessionObj != null ? (sessionObj['id'] ?? sessionObj['Id']) : data['id'];
                                    final extractedId = rawId is int ? rawId : (int.tryParse(rawId?.toString() ?? '') ?? 0);
                                    final extractedCode = (sessionObj != null ? (sessionObj['sessionCode'] ?? sessionObj['SessionCode']) : null)?.toString() ?? code;

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AttendanceQrScreen(
                                          title: title,
                                          sessionCode: extractedCode,
                                          sessionId: extractedId,
                                          durationMinutes: duration,
                                          allowedRadiusMeters: radius,
                                        ),
                                      ),
                                    );
                                  } else {
                                    _showErrorSnackBar(data['message'] ?? 'Lỗi tạo phiên!');
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  _showErrorSnackBar('Lỗi kết nối: $e');
                                }
                              },
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text('Tạo & Hiển thị QR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextField _dialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperStyle: const TextStyle(fontSize: 11),
        counterText: '',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _currentUser?.fullName ?? 'Quản trị viên';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primary,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: _logout,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF42A5F5), AppTheme.primaryDark]),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Center(
                                child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.admin_panel_settings_rounded, size: 12, color: Color(0xFF80DEEA)),
                                        const SizedBox(width: 4),
                                        Text(
                                          _currentUser?.role ?? 'Admin',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Quick info
                        Row(
                          children: [
                            _buildInfoChip(Icons.person_rounded, _currentUser?.username ?? 'admin'),
                            const SizedBox(width: 10),
                            _buildInfoChip(Icons.school_rounded, 'HUTECH 2026'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section title
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Text(
                        'Công cụ quản trị',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ),

                    // Primary action - Create attendance session
                    _buildPrimaryActionCard(),
                    const SizedBox(height: 14),

                    // Secondary actions grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.people_rounded,
                            title: 'Quản lý\nSinh viên',
                            subtitle: 'CRUD',
                            gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)]),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentListScreen())),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.analytics_rounded,
                            title: 'Thống kê\nBáo cáo',
                            subtitle: 'Tỉ lệ chuyên cần',
                            gradient: const LinearGradient(colors: [Color(0xFFF57C00), Color(0xFFE65100)]),
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.notifications_active_rounded,
                            title: 'Thông báo\nHệ thống',
                            subtitle: 'Gửi thông báo',
                            gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)]),
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.settings_rounded,
                            title: 'Cài đặt\nHệ thống',
                            subtitle: 'Cấu hình chung',
                            gradient: const LinearGradient(colors: [Color(0xFF00796B), Color(0xFF004D40)]),
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // System info
                    _buildSystemInfoCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionCard() {
    return GestureDetector(
      onTap: _showCreateSessionDialog,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00897B), Color(0xFF00BFA5)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.success.withValues(alpha: 0.3),
              blurRadius: 20, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mở Phiên Điểm Danh', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('QR động + Mã 6 số + Face ID + GPS', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_rounded, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Thông tin hệ thống', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow('📱', 'Ứng dụng', 'CheckIn Pro v1.0.0'),
          _buildInfoRow('🔐', 'Bảo mật', 'JWT + OTP + Face ID + GPS'),
          _buildInfoRow('📡', 'API', 'ASP.NET Core 8.0'),
          _buildInfoRow('🎓', 'Sinh viên', 'Nguyễn Hữu Thắng · 2380602081'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
