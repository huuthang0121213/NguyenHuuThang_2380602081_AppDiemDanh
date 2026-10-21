import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // Lưu token vào SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Lấy token từ SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Lưu thông tin người dùng vào máy
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Lấy thông tin người dùng đã lưu
  static Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Xóa token và đăng xuất
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Kiểm tra token có hợp lệ và còn hạn không
  static Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    try {
      return !JwtDecoder.isExpired(token);
    } catch (_) {
      return false;
    }
  }

  // Lấy Role từ Token đã giải mã
  static Future<String?> getRoleFromToken() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final decodedToken = JwtDecoder.decode(token);
      return decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
             decodedToken['role'];
    } catch (_) {
      return null;
    }
  }

  static dynamic _parseResponse(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return {
        'success': false,
        'message': 'Phản hồi từ máy chủ (${response.statusCode}): ${utf8.decode(response.bodyBytes)}'
      };
    }
  }

  // Đăng nhập (Bước 1: Kiểm tra tài khoản & gửi mã OTP)
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = Uri.parse(ApiConfig.login);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = _parseResponse(response);

      if (response.statusCode == 200 && data['success'] == true) {
        // Nếu yêu cầu xác thực OTP 2 bước
        if (data['requiresOtp'] == true) {
          return {
            'success': true,
            'requiresOtp': true,
            'email': data['email'],
            'devOtp': data['devOtp'],
            'message': data['message'],
          };
        }

        // Nếu trực tiếp có token (fallback)
        final token = data['token'];
        if (token != null) {
          await saveToken(token);
        }
        if (data['user'] != null) {
          final user = UserModel.fromJson(data['user']);
          await saveUser(user);
        }
        return {'success': true, 'requiresOtp': false, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Đăng nhập thất bại!'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối đến máy chủ: $e'};
    }
  }

  // Xác thực mã OTP (Bước 2: Kiểm tra OTP & nhận JWT Token)
  static Future<Map<String, dynamic>> verifyOtp(String username, String otpCode) async {
    try {
      final url = Uri.parse(ApiConfig.verifyOtp);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'otpCode': otpCode.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      final data = _parseResponse(response);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['token'];
        if (token != null) {
          await saveToken(token);
        }
        if (data['user'] != null) {
          final user = UserModel.fromJson(data['user']);
          await saveUser(user);
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Xác thực OTP thất bại!'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối đến máy chủ: $e'};
    }
  }

  // Gửi lại mã OTP
  static Future<Map<String, dynamic>> resendOtp(String username) async {
    try {
      final url = Uri.parse(ApiConfig.resendOtp);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      final data = _parseResponse(response);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'devOtp': data['devOtp'],
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gửi lại mã OTP thất bại!'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối đến máy chủ: $e'};
    }
  }

  // Gửi mã OTP xác nhận đăng ký về email
  static Future<Map<String, dynamic>> sendRegisterOtp({
    required String username,
    required String email,
    required String fullName,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.sendRegisterOtp);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'email': email.trim(),
          'fullName': fullName.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      final data = _parseResponse(response);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'email': data['email'],
          'devOtp': data['devOtp'],
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Không thể gửi mã OTP!'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối đến máy chủ: $e'};
    }
  }

  // Đăng ký (Kèm mã OTP xác thực)
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? studentCode,
    String role = 'Student',
    String? otpCode,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.register);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
          'fullName': fullName.trim(),
          'studentCode': studentCode?.trim(),
          'role': role,
          'otpCode': otpCode?.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      final data = _parseResponse(response);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Đăng ký thất bại!'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối đến máy chủ: $e'};
    }
  }
}
