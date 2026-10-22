import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/pin_code_field.dart';
import '../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentCodeController = TextEditingController();
  String _selectedRole = 'Student';

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  // Step tracking
  int _currentStep = 0; // 0 = Account info, 1 = Personal info

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final _steps = ['Thông tin tài khoản', 'Thông tin cá nhân'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _studentCodeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  bool _validateStep0() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập tên đăng nhập!');
      return false;
    }
    if (username.length < 4) {
      setState(() => _errorMessage = 'Tên đăng nhập phải có ít nhất 4 ký tự!');
      return false;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mật khẩu!');
      return false;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự!');
      return false;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không khớp!');
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();

    if (fullName.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập họ và tên!');
      return false;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Vui lòng nhập địa chỉ email hợp lệ!');
      return false;
    }
    return true;
  }

  void _goToNextStep() {
    if (_currentStep == 0) {
      if (!_validateStep0()) return;
    }
    setState(() {
      _errorMessage = null;
      _currentStep = 1;
    });
    _animController.forward(from: 0);
    HapticFeedback.selectionClick();
  }

  void _goToPrevStep() {
    setState(() {
      _errorMessage = null;
      _currentStep = 0;
    });
    _animController.forward(from: 0);
  }

  Future<void> _handleRegister() async {
    if (!_validateStep1()) return;

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final fullName = _fullNameController.text.trim();
    final studentCode = _studentCodeController.text.trim();

    setState(() { _isLoading = true; _errorMessage = null; });

    final otpRes = await AuthService.sendRegisterOtp(
      username: username,
      email: email,
      fullName: fullName,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (otpRes['success'] == true) {
      HapticFeedback.lightImpact();
      final verified = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (ctx) => _RegisterOtpSheet(
          username: username,
          email: email,
          fullName: fullName,
          password: _passwordController.text,
          studentCode: studentCode.isNotEmpty ? studentCode : null,
          role: _selectedRole,
          devOtp: otpRes['devOtp'],
        ),
      );

      if (verified == true && mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Đăng ký thành công! Vui lòng đăng nhập.', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } else {
      setState(() => _errorMessage = otpRes['message'] ?? 'Không thể gửi mã OTP xác nhận!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Custom AppBar ─────────────────────────────────────
              _buildAppBar(),

              // ── Step Progress ─────────────────────────────────────
              _buildStepIndicator(),

              // ── Form Content ──────────────────────────────────────
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _currentStep == 0 ? _buildStep0() : _buildStep1(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
            onPressed: _currentStep == 0 ? () => Navigator.pop(context) : _goToPrevStep,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Tạo Tài Khoản',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Bước ${_currentStep + 1} / 2 · ${_steps[_currentStep]}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: _currentStep >= 1 ? Colors.white : Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        _buildSectionHeader(
          icon: Icons.manage_accounts_rounded,
          title: 'Thông tin tài khoản',
          subtitle: 'Tạo username và mật khẩu để đăng nhập',
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null) ...[
          _buildErrorBanner(_errorMessage!),
          const SizedBox(height: 16),
        ],

        _buildLabeledField(
          label: 'Tên đăng nhập *',
          child: TextField(
            controller: _usernameController,
            onChanged: (_) => _clearError(),
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: 'Tối thiểu 4 ký tự, không dấu',
              icon: Icons.person_rounded,
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildLabeledField(
          label: 'Mật khẩu *',
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (_) => _clearError(),
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: 'Ít nhất 6 ký tự',
              icon: Icons.lock_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppTheme.textSecondary, size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildLabeledField(
          label: 'Xác nhận mật khẩu *',
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            onChanged: (_) => _clearError(),
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: 'Nhập lại mật khẩu',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppTheme.textSecondary, size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        _buildNextButton(
          label: 'Tiếp theo →',
          icon: Icons.arrow_forward_rounded,
          onTap: _goToNextStep,
        ),
        const SizedBox(height: 20),

        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Đã có tài khoản? ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          icon: Icons.badge_rounded,
          title: 'Thông tin cá nhân',
          subtitle: 'Mã OTP sẽ được gửi đến email để xác thực',
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null) ...[
          _buildErrorBanner(_errorMessage!),
          const SizedBox(height: 16),
        ],

        _buildLabeledField(
          label: 'Họ và tên *',
          child: TextField(
            controller: _fullNameController,
            onChanged: (_) => _clearError(),
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: 'Nhập họ và tên đầy đủ',
              icon: Icons.account_circle_rounded,
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildLabeledField(
          label: 'Email nhận OTP *',
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _clearError(),
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: 'email@student.edu.vn',
              icon: Icons.email_rounded,
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildLabeledField(
          label: 'Mã số sinh viên (MSSV)',
          badge: 'Tùy chọn',
          child: TextField(
            controller: _studentCodeController,
            keyboardType: TextInputType.number,
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: 'Ví dụ: 2380602081',
              icon: Icons.badge_outlined,
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildLabeledField(
          label: 'Vai trò *',
          child: _buildRoleSelector(),
        ),
        const SizedBox(height: 32),

        _buildNextButton(
          label: 'GỬI MÃ OTP XÁC THỰC',
          icon: Icons.send_rounded,
          onTap: _handleRegister,
          isLoading: _isLoading,
        ),

        const SizedBox(height: 16),
        Center(
          child: Text(
            'OTP sẽ được gửi ngay đến email của bạn',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    final roles = [
      {'value': 'Student', 'label': 'Sinh viên', 'icon': Icons.school_rounded},
      {'value': 'Teacher', 'label': 'Giảng viên', 'icon': Icons.person_rounded},
      {'value': 'Admin', 'label': 'Quản trị viên', 'icon': Icons.admin_panel_settings_rounded},
    ];

    return Row(
      children: roles.map((role) {
        final isSelected = _selectedRole == role['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedRole = role['value'] as String);
            },
            child: Container(
              margin: EdgeInsets.only(right: role['value'] == 'Admin' ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary.withValues(alpha: 0.08) : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.border,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    role['icon'] as IconData,
                    color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isLoading ? null : const LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.primary],
        ),
        color: isLoading ? AppTheme.border : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isLoading ? [] : [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primaryLight, AppTheme.primary]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
    String? badge,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge, style: const TextStyle(fontSize: 10, color: AppTheme.success, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: AppTheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppTheme.error, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppTheme.primary),
      ),
      suffixIcon: suffixIcon,
    );
  }

  TextStyle get _inputTextStyle => const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary);

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }
}

// ==============================================================================
// REGISTER OTP VERIFICATION SHEET
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

class _RegisterOtpSheetState extends State<_RegisterOtpSheet>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  int _secondsRemaining = 300;
  Timer? _timer;
  bool _isSubmitting = false;
  String? _dialogError;
  String? _currentDevOtp;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _currentDevOtp = widget.devOtp;
    _startTimer();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
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
    _shakeController.dispose();
    super.dispose();
  }

  String _formatTimer(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Color get _timerColor {
    if (_secondsRemaining > 180) return AppTheme.success;
    if (_secondsRemaining > 60) return AppTheme.warning;
    return AppTheme.error;
  }

  Future<void> _handleConfirm() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      _shakeController.forward(from: 0);
      setState(() => _dialogError = 'Vui lòng nhập đủ 6 chữ số mã OTP!');
      return;
    }

    setState(() { _isSubmitting = true; _dialogError = null; });

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
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
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
      setState(() => _currentDevOtp = res['devOtp']);
      _startTimer();
      _otpController.clear();
      HapticFeedback.lightImpact();
    } else if (mounted) {
      setState(() => _dialogError = res['message'] ?? 'Không thể gửi lại OTP!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 8),

            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.success, Color(0xFF00897B)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.success.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),

            const Text(
              'Xác Thực Email Đăng Ký',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Mã OTP đã gửi đến',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 4),
            Text(
              widget.email,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.success),
            ),
            const SizedBox(height: 24),

            // Dev OTP chip
            if (_currentDevOtp != null)
              GestureDetector(
                onTap: () {
                  _otpController.text = _currentDevOtp!;
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.key_rounded, color: AppTheme.warning, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mã OTP (môi trường dev)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            Text(
                              _currentDevOtp!,
                              style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold,
                                color: Color(0xFF7B4F00), letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.warning, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Điền', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),

            if (_dialogError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_rounded, color: AppTheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_dialogError!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            PinCodeField(
              controller: _otpController,
              length: 6,
              onCompleted: (_) => _handleConfirm(),
            ),
            const SizedBox(height: 20),

            // Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_rounded, size: 16, color: _timerColor),
                    const SizedBox(width: 6),
                    Text('Hết hạn sau: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text(
                      _formatTimer(_secondsRemaining),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _timerColor),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _handleResend,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.primaryLight),
                  label: const Text('Gửi lại', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryLight)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _secondsRemaining / 300,
                minHeight: 4,
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: AppTheme.border, width: 1.5),
                    ),
                    child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.success, Color(0xFF00897B)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.success.withValues(alpha: 0.3),
                          blurRadius: 12, offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSubmitting ? null : _handleConfirm,
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('TẠO TÀI KHOẢN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                        ),
                      ),
                    ),
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
