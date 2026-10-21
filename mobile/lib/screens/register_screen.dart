import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
      // Bước 2: Hiển thị hộp thoại nhập OTP xác thực email trước khi tạo tài khoản
      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _RegisterOtpDialog(
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
            backgroundColor: Colors.green,
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
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản mới'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade800)),
              ),

            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Tên đăng nhập *',
                prefixIcon: const Icon(Icons.account_circle_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Họ và tên *',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _studentCodeController,
              decoration: InputDecoration(
                labelText: 'Mã số sinh viên (MSSV)',
                prefixIcon: const Icon(Icons.numbers_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email nhận mã OTP *',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mật khẩu (ít nhất 6 ký tự) *',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Vai trò (Role)',
                prefixIcon: const Icon(Icons.security_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('XÁC NHẬN & NHẬN MÃ OTP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// HỘP THOẠI NHẬP OTP XÁC NHẬN EMAIL ĐĂNG KÝ
// ==============================================================================
class _RegisterOtpDialog extends StatefulWidget {
  final String username;
  final String email;
  final String fullName;
  final String password;
  final String? studentCode;
  final String role;
  final String? devOtp;

  const _RegisterOtpDialog({
    required this.username,
    required this.email,
    required this.fullName,
    required this.password,
    this.studentCode,
    required this.role,
    this.devOtp,
  });

  @override
  State<_RegisterOtpDialog> createState() => _RegisterOtpDialogState();
}

class _RegisterOtpDialogState extends State<_RegisterOtpDialog> {
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
        const SnackBar(content: Text('Mã OTP mới đã được gửi!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_read_outlined, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Xác thực OTP Email', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Hệ thống đã gửi mã OTP 6 số đến email đăng ký: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text(widget.email, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 12),

            if (_currentDevOtp != null)
              InkWell(
                onTap: () => _otpController.text = _currentDevOtp!,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.key, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'OTP thử nghiệm: $_currentDevOtp (chạm điền)',
                          style: TextStyle(fontSize: 12, color: Colors.brown.shade800, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_dialogError != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_dialogError!, style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
              ),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '------',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(_formatTimer(_secondsRemaining), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton(
                  onPressed: _handleResend,
                  child: const Text('Gửi lại mã', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('XÁC NHẬN ĐĂNG KÝ'),
        ),
      ],
    );
  }
}
