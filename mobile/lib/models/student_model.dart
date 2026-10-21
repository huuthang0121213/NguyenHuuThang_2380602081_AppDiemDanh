class StudentModel {
  final int id;
  final String studentCode;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String className;
  final bool isActive;
  final DateTime? createdAt;

  StudentModel({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.className,
    this.isActive = true,
    this.createdAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      studentCode: json['studentCode'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      className: json['className'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentCode': studentCode,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'className': className,
      'isActive': isActive,
    };
  }
}
