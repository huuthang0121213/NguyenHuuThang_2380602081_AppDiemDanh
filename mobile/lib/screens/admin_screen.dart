import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'student_list_screen.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getSavedUser();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _showCreateSessionDialog() async {
    final titleController = TextEditingController(text: 'Buổi học Lập trình di động');
    final sessionCodeController = TextEditingController(text: 'SES-${DateTime.now().millisecondsSinceEpoch % 100000}');
    final durationController = TextEditingController(text: '30');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tạo phiên điểm danh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Tên buổi học *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sessionCodeController,
              decoration: const InputDecoration(labelText: 'Mã phiên (Session Code) *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Thời lượng (phút) *', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final title = titleController.text.trim();
              final code = sessionCodeController.text.trim();
              final duration = int.tryParse(durationController.text.trim()) ?? 30;

              if (title.isEmpty || code.isEmpty) return;

              Navigator.pop(ctx);

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
                  }),
                );

                if (!mounted) return;
                final data = jsonDecode(utf8.decode(response.bodyBytes));
                if (response.statusCode == 200 && data['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tạo phiên điểm danh thành công! SessionCode: $code'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${data['message']}'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Tạo phiên'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Trị Hệ Thống'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Admin Profile Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFF1E3A8A),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.admin_panel_settings, size: 36, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentUser?.fullName ?? 'Quản Trị Viên',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tài khoản: ${_currentUser?.username ?? "admin"}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            'Quyền hạn: ${_currentUser?.role ?? "Admin"}',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Chức năng quản trị',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Card 1: Quản lý sinh viên
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF3B82F6),
                  child: Icon(Icons.people, color: Colors.white),
                ),
                title: const Text('Quản lý Sinh viên (CRUD)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Xem danh sách, thêm mới, sửa, xóa sinh viên'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentListScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Card 2: Tạo phiên điểm danh mới
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF10B981),
                  child: Icon(Icons.qr_code_2, color: Colors.white),
                ),
                title: const Text('Tạo Phiên Điểm Danh', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Mở phiên điểm danh để sinh viên quét mã'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showCreateSessionDialog,
              ),
            ),
            const SizedBox(height: 12),

            // Card 3: Xem báo cáo thống kê
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: const ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xFFF59E0B),
                  child: Icon(Icons.analytics, color: Colors.white),
                ),
                title: Text('Thống Kê Điểm Danh', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Báo cáo tỉ lệ chuyên cần theo từng lớp học'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
