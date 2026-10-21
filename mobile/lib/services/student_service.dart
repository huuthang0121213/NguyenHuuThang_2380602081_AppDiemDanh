import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/student_model.dart';
import 'auth_service.dart';

class StudentService {
  // Lấy danh sách sinh viên
  static Future<List<StudentModel>> getStudents({String? search}) async {
    try {
      final token = await AuthService.getToken();
      var urlStr = ApiConfig.students;
      if (search != null && search.isNotEmpty) {
        urlStr += '?search=${Uri.encodeComponent(search)}';
      }

      final response = await http.get(
        Uri.parse(urlStr),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((item) => StudentModel.fromJson(item)).toList();
      } else {
        throw Exception('Lỗi tải danh sách: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Thêm sinh viên mới
  static Future<bool> addStudent(StudentModel student) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse(ApiConfig.students),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'studentCode': student.studentCode,
          'fullName': student.fullName,
          'email': student.email,
          'phoneNumber': student.phoneNumber,
          'className': student.className,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Xóa sinh viên
  static Future<bool> deleteStudent(int id) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse(ApiConfig.studentDetail(id)),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
