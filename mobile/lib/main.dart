import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load file .env cấu hình API (có fallback nếu chưa có file)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Không tìm thấy file .env, sử dụng cấu hình mặc định: $e");
  }

  // Kiểm tra phiên đăng nhập tự động
  Widget initialScreen = const LoginScreen();
  try {
    final isValid = await AuthService.isTokenValid();
    if (isValid) {
      final role = await AuthService.getRoleFromToken();
      final user = await AuthService.getSavedUser();
      if (role == 'Admin' || user?.role == 'Admin' || role == 'Teacher' || user?.role == 'Teacher') {
        initialScreen = const AdminScreen();
      } else {
        initialScreen = const HomeScreen();
      }
    }
  } catch (e) {
    debugPrint("Lỗi kiểm tra token tự động: $e");
    initialScreen = const LoginScreen();
  }

  runApp(AttendanceApp(initialScreen: initialScreen));
}

class AttendanceApp extends StatelessWidget {
  final Widget initialScreen;

  const AttendanceApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Điểm Danh Sinh Viên - 2380602081',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: initialScreen,
    );
  }
}
