class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String? studentCode;
  final String role;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    this.studentCode,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      studentCode: json['studentCode'],
      role: json['role'] ?? 'Student',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'studentCode': studentCode,
      'role': role,
    };
  }
}
