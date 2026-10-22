import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/pin_code_field.dart';
import '../main.dart';
import 'home_screen.dart';
import 'admin_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu!');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    final result = await AuthService.login(username, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (result['requiresOtp'] == true) {
        final email = result['email'] ?? 'email của bạn';
        final devOtp = result['devOtp'];

        HapticFeedback.lightImpact();
        final verified = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          builder: (ctx) => _OtpVerificationSheet(
            username: username,
            maskedEmail: email,
            devOtp: devOtp,
          ),
        );

        if (verified == true && mounted) {
          await _navigateAfterLogin();
        }
        return;
      }
      await _navigateAfterLogin();
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _errorMessage = result['message'] ?? 'Đăng nhập không thành công!');
    }
  }

  Future<void> _navigateAfterLogin() async {
    final role = await AuthService.getRoleFromToken();
    final user = await AuthService.getSavedUser();

    if (!mounted) return;

    HapticFeedback.mediumImpact();
    if (role == 'Admin' || user?.role == 'Admin' || role == 'Teacher' || user?.role == 'Teacher') {
      Navigator.pushReplacement(context, _createRoute(const AdminScreen()));
    } else {
      Navigator.pushReplacement(context, _createRoute(const HomeScreen()));
    }
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  void _fillSampleAccount(String username, String password) {
    HapticFeedback.selectionClick();
    _usernameController.text = username;
    _passwordController.text = password;
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Logo & Brand Header ──────────────────────────────
                      _buildBrandHeader(),
                      const SizedBox(height: 32),

                      // ── Main Login Card ──────────────────────────────────
                      _buildLoginCard(),
                      const SizedBox(height: 20),

                      // ── Footer ───────────────────────────────────────────
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        // App Icon with glow effect
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF42A5F5), Color(0xFF1A237E)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF42A5F5).withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.how_to_reg_rounded, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 20),
        const Text(
          'CheckIn Pro',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF80DEEA)),
              const SizedBox(width: 6),
              Text(
                'OTP Email · GPS · Nhận diện khuôn mặt',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D1752).withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Đăng Nhập',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Nhập thông tin để truy cập hệ thống',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            // Error banner
            if (_errorMessage != null) ...[
              _buildErrorBanner(_errorMessage!),
              const SizedBox(height: 16),
            ],

            // Username field
            _buildInputField(
              controller: _usernameController,
              label: 'Tên đăng nhập / MSSV',
              hint: 'Nhập username hoặc mã số sinh viên',
              icon: Icons.person_rounded,
              keyboardType: TextInputType.text,
              onChanged: (_) { if (_errorMessage != null) setState(() => _errorMessage = null); },
            ),
            const SizedBox(height: 14),

            // Password field
            _buildPasswordField(),
            const SizedBox(height: 28),

            // Login button
            _buildLoginButton(),
            const SizedBox(height: 20),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: AppTheme.border, thickness: 1.2)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('hoặc', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 13)),
                ),
                Expanded(child: Divider(color: AppTheme.border, thickness: 1.2)),
              ],
            ),
            const SizedBox(height: 20),

            // Register link
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Chưa có tài khoản? ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text(
                      'Đăng ký ngay →',
                      style: TextStyle(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick demo accounts
            _buildDemoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
          decoration: InputDecoration(
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
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mật khẩu',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          onChanged: (_) { if (_errorMessage != null) setState(() => _errorMessage = null); },
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nhập mật khẩu của bạn',
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_rounded, size: 18, color: AppTheme.primary),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: _isLoading ? null : const LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.primary, AppTheme.primaryDark],
        ),
        color: _isLoading ? AppTheme.border : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading ? [] : [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'ĐĂNG NHẬP & NHẬN OTP',
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold,
                          color: Colors.white, letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded, size: 14, color: AppTheme.warning),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tài khoản kiểm thử (1 chạm)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDemoButton(
                  label: '👨‍💼 Admin',
                  sublabel: 'Giảng viên',
                  onTap: () => _fillSampleAccount('admin', 'Admin@123456'),
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDemoButton(
                  label: '👨‍🎓 Sinh viên',
                  sublabel: '2380602081',
                  onTap: () => _fillSampleAccount('2380602081', 'Thang@123456'),
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoButton({
    required String label,
    required String sublabel,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(sublabel, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_rounded, color: AppTheme.error, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.error, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Nguyễn Hữu Thắng · MSSV: 2380602081',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          'Khoa CNTT · HUTECH University 2026',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
        ),
      ],
    );
  }
}

// ==============================================================================
// OTP VERIFICATION BOTTOM SHEET - PREMIUM FINTECH STYLE
// ==============================================================================
class _OtpVerificationSheet extends StatefulWidget {
  final String username;
  final String maskedEmail;
  final String? devOtp;

  const _OtpVerificationSheet({
    required this.username,
    required this.maskedEmail,
    this.devOtp,
  });

  @override
  State<_OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<_OtpVerificationSheet>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  int _secondsRemaining = 300;
  Timer? _countdownTimer;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _dialogError;
  String? _currentDevOtp;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _currentDevOtp = widget.devOtp;
    _startCountdown();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = 300);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _timerProgress => _secondsRemaining / 300;
  Color get _timerColor {
    if (_secondsRemaining > 180) return AppTheme.success;
    if (_secondsRemaining > 60) return AppTheme.warning;
    return AppTheme.error;
  }

  Future<void> _handleVerifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      _shakeController.forward(from: 0);
      setState(() => _dialogError = 'Vui lòng nhập đủ 6 chữ số mã OTP!');
      return;
    }

    setState(() { _isVerifying = true; _dialogError = null; });

    final res = await AuthService.verifyOtp(widget.username, code);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (res['success'] == true) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      setState(() => _dialogError = res['message'] ?? 'Mã OTP không chính xác!');
    }
  }

  Future<void> _handleResendOtp() async {
    setState(() { _isResending = true; _dialogError = null; });

    final res = await AuthService.resendOtp(widget.username);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (res['success'] == true) {
      setState(() => _currentDevOtp = res['devOtp']);
      _startCountdown();
      _otpController.clear();
      HapticFeedback.lightImpact();
    } else {
      setState(() => _dialogError = res['message'] ?? 'Không thể gửi lại mã OTP!');
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
            // Handle bar
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),

            // Animated email icon
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF42A5F5), AppTheme.primaryLight],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryLight.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),

            const Text(
              'Xác Thực OTP Email',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mã xác thực 6 số đã gửi đến',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 4),
            Text(
              widget.maskedEmail,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryLight,
              ),
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
                            const Text(
                              'Mã OTP (môi trường dev)',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                            Text(
                              _currentDevOtp!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7B4F00),
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.warning,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Điền',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Error message
            if (_dialogError != null) ...[
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (_, child) => Transform.translate(
                  offset: Offset(10 * (0.5 - (_shakeAnimation.value - 0.5).abs()) * 2, 0),
                  child: child,
                ),
                child: Container(
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
                      Expanded(
                        child: Text(_dialogError!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // OTP input boxes
            PinCodeField(
              controller: _otpController,
              length: 6,
              onCompleted: (_) => _handleVerifyOtp(),
            ),
            const SizedBox(height: 20),

            // Timer & progress
            _buildTimerRow(),
            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerRow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.timer_rounded, size: 16, color: _timerColor),
                const SizedBox(width: 6),
                Text(
                  'Hết hạn sau: ',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                Text(
                  _formatTimer(_secondsRemaining),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _timerColor,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _isResending ? null : _handleResendOtp,
              icon: _isResending
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryLight))
                  : const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.primaryLight),
              label: Text(
                'Gửi lại',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _isResending ? AppTheme.textSecondary : AppTheme.primaryLight),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _timerProgress,
            minHeight: 4,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
              gradient: const LinearGradient(colors: [AppTheme.primaryLight, AppTheme.primary]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isVerifying ? null : _handleVerifyOtp,
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: _isVerifying
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('XÁC NHẬN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
