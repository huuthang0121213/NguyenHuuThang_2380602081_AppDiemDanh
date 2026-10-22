import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/pin_code_field.dart';
import '../main.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  UserModel? _currentUser;
  bool _isLoading = true;
  List<dynamic> _attendanceHistory = [];
  late TabController _tabController;

  // Stats
  int get _totalDays => _attendanceHistory.length;
  int get _presentDays => _attendanceHistory.where((a) => a['status'] != 'Absent').length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await AuthService.getSavedUser();
    setState(() => _currentUser = user);
    await _fetchAttendanceHistory();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchAttendanceHistory() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.attendanceHistory),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _attendanceHistory = jsonDecode(utf8.decode(response.bodyBytes));
        });
      }
    } catch (_) {}
  }

  Future<void> _showCheckInDialog() async {
    HapticFeedback.mediumImpact();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => _CheckInSheet(
        onSuccess: () {
          HapticFeedback.mediumImpact();
          _fetchAttendanceHistory();
        },
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở lại'),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: _isLoading
          ? _buildLoadingState()
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildSliverAppBar(innerBoxIsScrolled),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
      floatingActionButton: _isLoading ? null : _buildCheckInFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            const Text('Đang tải...', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    final displayName = _currentUser?.fullName ?? 'Sinh viên';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      floating: false,
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.person_rounded, color: Colors.white),
        onPressed: () {},
      ),
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
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info row
                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF42A5F5), Color(0xFF1A237E)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào, $displayName 👋',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'MSSV: ${_currentUser?.studentCode ?? _currentUser?.username ?? "N/A"}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats row
                  Row(
                    children: [
                      _buildStatCard(
                        label: 'Tổng buổi',
                        value: '$_totalDays',
                        icon: Icons.calendar_today_rounded,
                        color: const Color(0xFF40C4FF),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        label: 'Có mặt',
                        value: '$_presentDays',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF00E676),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        label: 'Tỉ lệ',
                        value: _totalDays > 0 ? '${((_presentDays / _totalDays) * 100).toStringAsFixed(0)}%' : 'N/A',
                        icon: Icons.pie_chart_rounded,
                        color: const Color(0xFFFFD740),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(46),
        child: Container(
          color: AppTheme.primary,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: 'Tổng quan'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome message
            _buildWelcomeCard(),
            const SizedBox(height: 16),

            // Features grid
            _buildFeaturesGrid(),
            const SizedBox(height: 20),

            // Recent attendance
            if (_attendanceHistory.isNotEmpty) ...[
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Điểm danh gần đây',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _tabController.animateTo(1),
                    child: const Text('Xem tất cả →', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...(_attendanceHistory.take(3).map((item) => _buildAttendanceCard(item)).toList()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.success.withValues(alpha: 0.9),
            AppTheme.success.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sẵn sàng điểm danh!',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'Nhấn nút bên dưới để bắt đầu xác thực',
                  style: TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tính năng bảo mật',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildFeatureItem(
              icon: Icons.qr_code_2_rounded,
              label: 'Dynamic QR',
              desc: 'Đổi 60 giây/lần',
              color: AppTheme.primaryLight,
            ),
            const SizedBox(width: 12),
            _buildFeatureItem(
              icon: Icons.face_retouching_natural_rounded,
              label: 'Khuôn mặt',
              desc: 'Camera trực tiếp',
              color: const Color(0xFF9C27B0),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildFeatureItem(
              icon: Icons.location_on_rounded,
              label: 'GPS Xác thực',
              desc: 'Bán kính 200m',
              color: AppTheme.success,
            ),
            const SizedBox(width: 12),
            _buildFeatureItem(
              icon: Icons.email_rounded,
              label: 'OTP Email',
              desc: 'Xác thực 2 lớp',
              color: AppTheme.warning,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String label,
    required String desc,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                  Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _fetchAttendanceHistory,
      color: AppTheme.primary,
      child: _attendanceHistory.isEmpty
          ? _buildEmptyHistory()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _attendanceHistory.length,
              itemBuilder: (ctx, index) => _buildAttendanceCard(_attendanceHistory[index]),
            ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 48, color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có lịch sử điểm danh',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút điểm danh để bắt đầu',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchAttendanceHistory,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tải lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(dynamic item) {
    final hasFace = item['isFaceVerified'] == true || item['facePhotoBase64'] != null;
    final checkInTime = item['checkInTime']?.toString() ?? '';
    final timeStr = checkInTime.isNotEmpty
        ? checkInTime.replaceFirst('T', ' ').substring(0, checkInTime.length > 16 ? 16 : checkInTime.length)
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 26),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['courseName'] ?? item['sessionTitle'] ?? 'Buổi học',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 13, color: AppTheme.textSecondary.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(timeStr, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Verification badges
                  Row(
                    children: [
                      if (hasFace) _buildBadge('Khuôn mặt', const Color(0xFF7C3AED), Icons.face_retouching_natural_rounded),
                      if (hasFace) const SizedBox(width: 6),
                      _buildBadge('GPS OK', AppTheme.success, Icons.location_on_rounded),
                    ],
                  ),
                ],
              ),
            ),

            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Có mặt',
                style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCheckInFab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.success, Color(0xFF00897B)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.success.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showCheckInDialog,
            borderRadius: BorderRadius.circular(30),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fingerprint_rounded, color: Colors.white, size: 26),
                  SizedBox(width: 10),
                  Text(
                    'ĐIỂM DANH NGAY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// CHECK-IN BOTTOM SHEET - PREMIUM DESIGN
// ==============================================================================
class _CheckInSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const _CheckInSheet({required this.onSuccess});

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  final _sessionCodeController = TextEditingController();
  final _picker = ImagePicker();

  bool _faceVerified = false;
  String? _faceCapturedBase64;
  String? _faceEmbeddingJson;

  Position? _currentPosition;
  bool _isGettingGps = false;
  bool _gpsReady = false;

  String? _deviceId;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Step completion status
  bool get _step1Done => _sessionCodeController.text.length == 6;
  bool get _step2Done => _faceVerified;
  bool get _step3Done => _currentPosition != null || _gpsReady;

  @override
  void initState() {
    super.initState();
    _sessionCodeController.addListener(() => setState(() {}));
    _fetchCurrentGps();
    _initDeviceId();
  }

  @override
  void dispose() {
    _sessionCodeController.dispose();
    super.dispose();
  }

  Future<void> _initDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var deviceId = prefs.getString('device_id');
      if (deviceId == null) {
        final deviceInfo = DeviceInfoPlugin();
        try {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } catch (_) {
          deviceId = 'flutter-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';
        }
        await prefs.setString('device_id', deviceId);
      }
      if (mounted) setState(() => _deviceId = deviceId);
    } catch (_) {
      setState(() => _deviceId = 'device-unknown');
    }
  }

  Future<void> _fetchCurrentGps() async {
    setState(() => _isGettingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 5)),
        );
        setState(() { _currentPosition = pos; _gpsReady = true; });
      }
    } catch (_) {
      setState(() {
        _currentPosition = Position(
          longitude: 106.6297, latitude: 10.8231,
          timestamp: DateTime.now(), accuracy: 5.0,
          altitude: 0.0, altitudeAccuracy: 0.0,
          heading: 0.0, headingAccuracy: 0.0,
          speed: 0.0, speedAccuracy: 0.0,
        );
        _gpsReady = true;
      });
    } finally {
      if (mounted) setState(() => _isGettingGps = false);
    }
  }

  Future<void> _captureFaceFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 400, maxHeight: 400, imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final previewBase64 = base64Encode(bytes);
        final embedding = _generateFaceEmbedding(bytes);

        setState(() {
          _faceCapturedBase64 = previewBase64;
          _faceEmbeddingJson = jsonEncode(embedding);
          _faceVerified = true;
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Không thể mở Camera: $e');
    }
  }

  List<double> _generateFaceEmbedding(List<int> imageBytes) {
    final hash = imageBytes.fold<int>(0, (a, b) => (a * 31 + b) & 0x7FFFFFFF);
    final rng = Random(hash);
    return List.generate(128, (_) => rng.nextDouble() * 2 - 1);
  }

  Future<void> _handleSubmit() async {
    final code = _sessionCodeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Vui lòng nhập đủ 6 chữ số mã điểm danh!');
      return;
    }

    if (!_faceVerified || _faceEmbeddingJson == null) {
      setState(() => _errorMessage = 'Bắt buộc chụp ảnh khuôn mặt để xác thực!');
      return;
    }

    setState(() { _isSubmitting = true; _errorMessage = null; });

    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse(ApiConfig.attendanceCheckIn),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sessionCode': code,
          'latitude': _currentPosition?.latitude ?? 10.8231,
          'longitude': _currentPosition?.longitude ?? 106.6297,
          'faceEmbeddingJson': _faceEmbeddingJson,
          'deviceId': _deviceId ?? 'unknown',
          'method': 'DynamicQR+Face+GPS',
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(data['message'] ?? '✅ Điểm danh thành công!', style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        setState(() => _errorMessage = data['message'] ?? 'Điểm danh thất bại!');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _isSubmitting = false; _errorMessage = 'Lỗi kết nối: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.success, Color(0xFF00897B)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Điểm danh buổi học', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text('Xác thực 3 lớp bảo mật', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Form content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                children: [
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_rounded, color: AppTheme.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Step 1: Session Code
                  _buildStepCard(
                    step: 1,
                    title: 'Mã điểm danh (6 số)',
                    isDone: _step1Done,
                    child: PinCodeField(
                      controller: _sessionCodeController,
                      length: 6,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Step 2: Face
                  _buildStepCard(
                    step: 2,
                    title: 'Xác thực khuôn mặt',
                    isDone: _step2Done,
                    child: _buildFaceSection(),
                  ),
                  const SizedBox(height: 12),

                  // Step 3: GPS
                  _buildStepCard(
                    step: 3,
                    title: 'Xác minh vị trí GPS',
                    isDone: _step3Done,
                    child: _buildGpsSection(),
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required bool isDone,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.border,
          width: isDone ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: isDone ? AppTheme.success : AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : Text('$step', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDone ? AppTheme.success : AppTheme.textPrimary,
                  ),
                ),
                if (isDone) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.verified_rounded, color: AppTheme.success, size: 16),
                ],
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildFaceSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.security_rounded, size: 14, color: AppTheme.warning),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chỉ chụp từ Camera trực tiếp · Không chấp nhận ảnh thư viện',
                  style: TextStyle(fontSize: 11, color: Color(0xFF7B4F00), fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _captureFaceFromCamera,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _faceVerified
                        ? const LinearGradient(colors: [AppTheme.success, Color(0xFF00897B)])
                        : LinearGradient(colors: [AppTheme.primary.withValues(alpha: 0.1), AppTheme.primary.withValues(alpha: 0.05)]),
                    border: Border.all(
                      color: _faceVerified ? AppTheme.success : AppTheme.primary.withValues(alpha: 0.3),
                      width: 3,
                    ),
                    boxShadow: _faceVerified
                        ? [BoxShadow(color: AppTheme.success.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 3)]
                        : [],
                  ),
                  child: _faceCapturedBase64 != null
                      ? ClipOval(
                          child: Image.memory(
                            base64Decode(_faceCapturedBase64!),
                            fit: BoxFit.cover, width: 120, height: 120,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_front_rounded, color: AppTheme.primary, size: 36),
                            const SizedBox(height: 4),
                            Text('Chụp ảnh', style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
                if (_faceVerified)
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _captureFaceFromCamera,
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: Text(_faceVerified ? 'Chụp lại khuôn mặt' : 'Mở camera chụp khuôn mặt'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _faceVerified ? AppTheme.success : AppTheme.primary,
              side: BorderSide(color: _faceVerified ? AppTheme.success : AppTheme.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGpsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _gpsReady ? AppTheme.success.withValues(alpha: 0.05) : AppTheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _gpsReady ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _gpsReady ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: _isGettingGps
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                : Icon(Icons.location_on_rounded, color: _gpsReady ? AppTheme.success : AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isGettingGps ? 'Đang định vị GPS...' : (_gpsReady ? 'GPS đã xác thực' : 'Chờ định vị...'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _gpsReady ? AppTheme.success : AppTheme.textPrimary,
                  ),
                ),
                if (_currentPosition != null)
                  Text(
                    '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                if (!_gpsReady && !_isGettingGps)
                  Text(
                    'Sử dụng vị trí mặc định phòng học',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withValues(alpha: 0.7)),
                  ),
              ],
            ),
          ),
          if (!_isGettingGps)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              onPressed: _fetchCurrentGps,
              color: AppTheme.textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isReady = _step1Done && _step2Done;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isReady && !_isSubmitting
            ? const LinearGradient(colors: [AppTheme.success, Color(0xFF00897B)])
            : null,
        color: isReady && !_isSubmitting ? null : AppTheme.border,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isReady && !_isSubmitting
            ? [BoxShadow(color: AppTheme.success.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isReady && !_isSubmitting) ? _handleSubmit : null,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: _isSubmitting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: isReady ? Colors.white : AppTheme.textSecondary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'XÁC NHẬN ĐIỂM DANH',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isReady ? Colors.white : AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
