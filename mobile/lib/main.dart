import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cấu hình màu thanh trạng thái trong suốt
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

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
      title: 'CheckIn Pro - Điểm Danh Sinh Viên',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialScreen,
    );
  }
}

class AppTheme {
  // ─── Brand Colors ───────────────────────────────────────────────
  static const Color primary        = Color(0xFF1A237E); // Deep Indigo
  static const Color primaryLight   = Color(0xFF3949AB); // Indigo
  static const Color primaryDark    = Color(0xFF0D1752); // Dark Indigo
  static const Color accent         = Color(0xFF00BCD4); // Cyan
  static const Color success        = Color(0xFF00C853); // Vibrant Green
  static const Color warning        = Color(0xFFFFB300); // Amber
  static const Color error          = Color(0xFFE53935); // Red
  static const Color surface        = Color(0xFFF8FAFF); // Light Blue-White
  static const Color card           = Colors.white;
  static const Color textPrimary    = Color(0xFF0D1752);
  static const Color textSecondary  = Color(0xFF546E7A);
  static const Color border         = Color(0xFFE3E8F0);

  // ─── Gradients ──────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1752), Color(0xFF1A237E), Color(0xFF283593), Color(0xFF1565C0)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1752), Color(0xFF1A237E), Color(0xFF1565C0), Color(0xFF1E88E5)],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00897B), Color(0xFF00BFA5)],
  );

  // ─── Theme ──────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F4FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6), fontWeight: FontWeight.w400),
        prefixIconColor: primary,
      ),
    );
  }
}
