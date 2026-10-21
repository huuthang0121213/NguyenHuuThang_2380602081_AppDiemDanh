import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Base URL đọc từ file .env hoặc fallback mặc định cho Android Emulator
  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000/api';
  }

  // Auth endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get profile => '$baseUrl/auth/profile';

  // Students endpoints
  static String get students => '$baseUrl/students';
  static String studentDetail(int id) => '$baseUrl/students/$id';

  // Attendance endpoints
  static String get attendanceSession => '$baseUrl/attendance/session';
  static String get attendanceCheckIn => '$baseUrl/attendance/check-in';
  static String get attendanceHistory => '$baseUrl/attendance/history';
}
