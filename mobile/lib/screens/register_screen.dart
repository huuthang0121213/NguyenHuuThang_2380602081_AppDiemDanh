import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/pin_code_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentCodeController = TextEditingController();
  String _selectedRole = 'Student';

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _studentCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final studentCode = _studentCodeController.text.trim();

    if (username.isEmpty || password.isEmpty || fullName.isEmpty || email.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng điền đầy đủ các thông tin bắt buộc (*)!';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Mật khẩu phải chứa ít nhất 6 ký tự!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Bước 1: Gửi mã OTP xác nhận về Email đăng ký
    final otpRes = await AuthService.sendRegisterOtp(
      username: username,
      email: email,
      fullName: fullName,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (otpRes['success'] == true) {
      // Bước 2: Hiển thị BottomSheet nhập OTP xác thực email trước khi tạo tài khoản
      final verified = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _RegisterOtpSheet(
          username: username,
          email: email,
          fullName: fullName,
          password: password,
          studentCode: studentCode.isNotEmpty ? studentCode : null,
          role: _selectedRole,
          devOtp: otpRes['devOtp'],
        ),
      );

      if (verified == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký tài khoản thành công! Vui lòng đăng nhập.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _errorMessage = otpRes['message'] ?? 'Không thể gửi mã OTP xác nhận đăng ký!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Khoản Mới', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card form
            Card(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Thông Tin Tài Khoản',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Mã OTP xác thực sẽ được gửi trực tiếp đến email của bạn',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 18),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13)),
                      ),

                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Tên đăng nhập *',
                        prefixIcon: const Icon(Icons.account_circle_outlined, color: Color(0xFF2563EB)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Họ và tên *',
                        prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF2563EB)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _studentCodeController,
                      decoration: InputDecoration(
                        labelText: 'Mã số sinh viên (MSSV)',
                        hintText: 'Ví dụ: 2380602081',
                        prefixIcon: const Icon(Icons.numbers_outlined, color: Color(0xFF2563EB)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email nhận mã OTP *',
                        hintText: 'email@student.edu.vn',
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2563EB)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu (ít nhất 6 ký tự) *',
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2563EB)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Vai trò trong hệ thống *',
                        prefixIcon: const Icon(Icons.security_outlined, color: Color(0xFF2563EB)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Student', child: Text('Sinh viên (Student)')),
                        DropdownMenuItem(value: 'Teacher', child: Text('Giảng viên (Teacher)')),
                        DropdownMenuItem(value: 'Admin', child: Text('Quản trị viên (Admin)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.mark_email_read_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('TIẾP TỤC & GỬI MÃ OTP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// MODAL BOTTOM SHEET XÁC THỰC EMAIL KHI ĐĂNG KÝ
// ==============================================================================
class _RegisterOtpSheet extends StatefulWidget {
  final String username;
  final String email;
  final String fullName;
  final String password;
  final String? studentCode;
  final String role;
  final String? devOtp;

  const _RegisterOtpSheet({
    required this.username,
    required this.email,
    required this.fullName,
    required this.password,
    this.studentCode,
    required this.role,
    this.devOtp,
  });

  @override
  State<_RegisterOtpSheet> createState() => _RegisterOtpSheetState();
}

class _RegisterOtpSheetState extends State<_RegisterOtpSheet> {
  final _otpController = TextEditingController();
  int _secondsRemaining = 300;
  Timer? _timer;
  bool _isSubmitting = false;
  String? _dialogError;
  String? _currentDevOtp;

  @override
  void initState() {
    super.initState();
    _currentDevOtp = widget.devOtp;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 300);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  String _formatTimer(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Future<void> _handleConfirm() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _dialogError = 'Vui lòng nhập đủ 6 chữ số mã OTP!');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _dialogError = null;
    });

    final res = await AuthService.register(
      username: widget.username,
      email: widget.email,
      password: widget.password,
      fullName: widget.fullName,
      studentCode: widget.studentCode,
      role: widget.role,
      otpCode: code,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _dialogError = res['message'] ?? 'Xác nhận OTP thất bại!');
    }
  }

  Future<void> _handleResend() async {
    final res = await AuthService.sendRegisterOtp(
      username: widget.username,
      email: widget.email,
      fullName: widget.fullName,
    );
    if (res['success'] == true && mounted) {
      setState(() {
        _currentDevOtp = res['devOtp'];
      });
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã OTP mới đã được phát hành!'), backgroundColor: Color(0xFF10B981)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Xác Thực Email Đăng Ký',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text('Mã OTP đã gửi đến: ${widget.email}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_currentDevOtp != null)
              InkWell(
                onTap: () => _otpController.text = _currentDevOtp!,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                            children: [
                              const TextSpan(text: 'Mã OTP thử nghiệm: '),
                              TextSpan(
                                text: _currentDevOtp,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFB45309), fontFamily: 'monospace'),
                              ),
                              const TextSpan(text: ' (chạm để điền)'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_dialogError != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(_dialogError!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13)),
              ),

            // PinCodeField with 6 discrete boxes
            PinCodeField(
              controller: _otpController,
              length: 6,
              onCompleted: (_) => _handleConfirm(),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: _secondsRemaining > 60 ? const Color(0xFF64748B) : const Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    Text('Hiệu lực: ${_formatTimer(_secondsRemaining)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _secondsRemaining > 60 ? const Color(0xFF475569) : const Color(0xFFDC2626))),
                  ],
                ),
                TextButton.icon(
                  onPressed: _handleResend,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Gửi lại mã', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: const Text('HỦY', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                        : const Text('XÁC NHẬN TẠO TÀI KHOẢN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
