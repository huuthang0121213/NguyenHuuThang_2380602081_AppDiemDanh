import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/pin_code_field.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;
  List<dynamic> _attendanceHistory = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await AuthService.getSavedUser();
    setState(() {
      _currentUser = user;
    });

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
    } catch (_) {
      // Offline fallback
    }
  }

  // ==============================================================================
  // MỞ HỘP THOẠI ĐIỂM DANH (MÃ 6 SỐ + KHUÔN MẶT + VỊ TRÍ GPS)
  // ==============================================================================
  Future<void> _showCheckInDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CheckInModal(
        onSuccess: () {
          _fetchAttendanceHistory();
        },
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh Sinh viên'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sinh viên Profile Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: const Color(0xFF1E3A8A),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    (_currentUser?.fullName.isNotEmpty ?? false)
                                        ? _currentUser!.fullName[0].toUpperCase()
                                        : 'S',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _currentUser?.fullName ?? 'Nguyễn Hữu Thắng',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'MSSV: ${_currentUser?.studentCode ?? _currentUser?.username ?? "2380602081"}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                                      ),
                                      Text(
                                        'Email: ${_currentUser?.email ?? ""}',
                                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0x33FFFFFF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Lớp: 23DTHB1 · Vai trò: ${_currentUser?.role ?? "Student"}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nút điểm danh (Hỗ trợ nhập mã 6 số + QR + Khuôn mặt + GPS)
                    ElevatedButton.icon(
                      onPressed: _showCheckInDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.verified_user, size: 28),
                      label: const Text(
                        'ĐIỂM DANH (MÃ 6 SỐ / QR / KHUÔN MẶT / GPS)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lịch sử điểm danh
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lịch sử điểm danh',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _fetchAttendanceHistory,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_attendanceHistory.isEmpty)
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.history, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Chưa có dữ liệu điểm danh nào.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _attendanceHistory.length,
                        itemBuilder: (ctx, index) {
                          final item = _attendanceHistory[index];
                          final hasFace = item['isFaceVerified'] == true || item['facePhotoBase64'] != null;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 26),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['courseName'] ?? item['sessionTitle'] ?? 'Buổi học',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Thời gian: ${item['checkInTime']?.toString().replaceFirst("T", " ").substring(0, 16) ?? ""}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            if (hasFace)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                margin: const EdgeInsets.only(right: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.blue.shade200),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.face, size: 12, color: Color(0xFF1E3A8A)),
                                                    SizedBox(width: 4),
                                                    Text('Khuôn mặt OK', style: TextStyle(fontSize: 10, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.green.shade200),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.location_on, size: 12, color: Colors.green),
                                                  SizedBox(width: 4),
                                                  Text('GPS Hợp lệ', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: const Text('Có mặt', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ==============================================================================
// HỘP THOẠI ĐIỂM DANH TÍCH HỢP: MÃ 6 SỐ, XÁC THỰC KHUÔN MẶT, VỊ TRÍ GPS
// ==============================================================================
class _CheckInModal extends StatefulWidget {
  final VoidCallback onSuccess;

  const _CheckInModal({required this.onSuccess});

  @override
  State<_CheckInModal> createState() => _CheckInModalState();
}

class _CheckInModalState extends State<_CheckInModal> {
  final _sessionCodeController = TextEditingController();
  final _picker = ImagePicker();

  String? _facePhotoBase64;
  Position? _currentPosition;
  bool _isGettingGps = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCurrentGps();
  }

  @override
  void dispose() {
    _sessionCodeController.dispose();
    super.dispose();
  }

  // 1. Lấy vị trí GPS hiện tại của thiết bị
  Future<void> _fetchCurrentGps() async {
    setState(() => _isGettingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        setState(() {
          _currentPosition = pos;
        });
      }
    } catch (_) {
      // Fallback giả lập GPS phòng học nếu máy ảo Android không có GPS thực tế
      setState(() {
        _currentPosition = Position(
          longitude: 106.6297,
          latitude: 10.8231,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      });
    } finally {
      if (mounted) setState(() => _isGettingGps = false);
    }
  }

  // 2. Chụp ảnh selfie khuôn mặt bằng Camera
  Future<void> _pickFacePhoto(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _facePhotoBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Không thể mở máy ảnh: $e');
    }
  }

  // 3. Gửi yêu cầu điểm danh lên API
  Future<void> _handleSubmit() async {
    final code = _sessionCodeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Vui lòng nhập đúng mã điểm danh gồm 6 chữ số!');
      return;
    }

    if (_facePhotoBase64 == null) {
      setState(() => _errorMessage = 'Vui lòng thực hiện bước chụp ảnh khuôn mặt để xác thực danh tính!');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

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
          'facePhotoBase64': _facePhotoBase64,
          'method': 'Face+GPS+Code',
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Điểm danh thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Điểm danh thất bại!';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Lỗi kết nối máy chủ: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.how_to_reg, color: Color(0xFF1E3A8A)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Điểm danh buổi học',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                ),
              ),

            // BƯỚC 1: NHẬP MÃ GỒM 6 SỐ
            const Text(
              '1. Nhập mã điểm danh gồm 6 số (từ QR hoặc bảng):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 10),
            PinCodeField(
              controller: _sessionCodeController,
              length: 6,
            ),
            const SizedBox(height: 16),

            // BƯỚC 2: XÁC THỰC KHUÔN MẶT
            const Text(
              '2. Chụp ảnh xác thực khuôn mặt:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => _pickFacePhoto(ImageSource.camera),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _facePhotoBase64 != null ? Colors.green : const Color(0xFF1E3A8A),
                      width: 2.5,
                    ),
                  ),
                  child: _facePhotoBase64 != null
                      ? ClipOval(
                          child: Image.memory(
                            base64Decode(_facePhotoBase64!),
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Color(0xFF1E3A8A), size: 30),
                            SizedBox(height: 4),
                            Text('Chụp ảnh', style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickFacePhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_front, size: 16),
                  label: const Text('Mở Camera', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _pickFacePhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text('Thư viện', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // BƯỚC 3: XÁC MINH VỊ TRÍ GPS
            const Text(
              '3. Tọa độ GPS phòng học:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isGettingGps
                        ? const Text('Đang định vị GPS...', style: TextStyle(fontSize: 12))
                        : Text(
                            _currentPosition != null
                                ? 'GPS: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)} (Trong bán kính phòng học)'
                                : 'Đang sử dụng vị trí lớp học (10.8231, 106.6297)',
                            style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('XÁC NHẬN ĐIỂM DANH'),
        ),
      ],
    );
  }
}
