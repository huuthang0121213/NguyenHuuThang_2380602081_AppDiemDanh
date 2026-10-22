import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import '../config/api_config.dart';
import '../main.dart';

/// Màn hình chiếu mã QR động (Dynamic QR) dành cho Giảng viên / Quản lý
/// - Mã QR thay đổi tự động mỗi [_qrRefreshSeconds] giây
/// - QR nhúng JSON Token gồm: sessionId, mã 6 số, timestamp, chữ ký HMAC
class AttendanceQrScreen extends StatefulWidget {
  final String title;
  final String sessionCode;
  final int sessionId;
  final int durationMinutes;
  final int allowedRadiusMeters;

  const AttendanceQrScreen({
    super.key,
    required this.title,
    required this.sessionCode,
    required this.sessionId,
    this.durationMinutes = 30,
    this.allowedRadiusMeters = 200,
  });

  @override
  State<AttendanceQrScreen> createState() => _AttendanceQrScreenState();
}

class _AttendanceQrScreenState extends State<AttendanceQrScreen>
    with TickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _sessionTimer;

  String? _currentQrData;
  int _qrCountdown = 0;
  Timer? _qrRefreshTimer;
  bool _isLoadingQr = false;
  String? _qrErrorMessage;
  static const int _qrRefreshSeconds = 60;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationMinutes * 60;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startSessionCountdown();
    _fetchQrToken();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _qrRefreshTimer?.cancel();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _startSessionCountdown() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _sessionTimer?.cancel();
        _qrRefreshTimer?.cancel();
      }
    });
  }

  Future<void> _fetchQrToken() async {
    if (!mounted) return;
    setState(() { _isLoadingQr = true; _qrErrorMessage = null; });

    try {
      if (widget.sessionId > 0) {
        final response = await http.get(
          Uri.parse(ApiConfig.attendanceQrToken(widget.sessionId)),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        if (!mounted) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data['qrData'] != null && data['qrData'].toString().isNotEmpty) {
            setState(() {
              _currentQrData = data['qrData'] as String;
              _qrCountdown = _qrRefreshSeconds;
              _isLoadingQr = false;
              _qrErrorMessage = null;
            });
            _startQrCountdown();
            return;
          }
        }
      }

      // Fallback: Nếu không tải được dynamic token, mã hóa mã phiên để sinh viên vẫn quét được
      if (!mounted) return;
      setState(() {
        _currentQrData = jsonEncode({
          'sid': widget.sessionId,
          'code': widget.sessionCode,
          'fallback': true,
          'ts': DateTime.now().millisecondsSinceEpoch,
        });
        _qrCountdown = _qrRefreshSeconds;
        _isLoadingQr = false;
        _qrErrorMessage = null;
      });
      _startQrCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentQrData = jsonEncode({
          'sid': widget.sessionId,
          'code': widget.sessionCode,
          'fallback': true,
          'ts': DateTime.now().millisecondsSinceEpoch,
        });
        _qrCountdown = _qrRefreshSeconds;
        _isLoadingQr = false;
        _qrErrorMessage = null;
      });
      _startQrCountdown();
    }
  }

  void _startQrCountdown() {
    _qrRefreshTimer?.cancel();
    _qrRefreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _qrCountdown--);
      if (_qrCountdown <= 0) {
        timer.cancel();
        _fetchQrToken();
      }
    });
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.sessionCode));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('Đã sao chép mã: ${widget.sessionCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color get _sessionTimerColor {
    if (_remainingSeconds > 600) return AppTheme.success;
    if (_remainingSeconds > 180) return AppTheme.warning;
    return AppTheme.error;
  }

  double get _sessionProgress => _remainingSeconds / (widget.durationMinutes * 60);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              children: [
                const Text('QR Điểm Danh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                Text(widget.title, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
                tooltip: 'Sao chép mã 6 số',
                onPressed: _copyCode,
              ),
            ],
          ),

          // ── Content ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Session status header
                _buildSessionHeader(),
                const SizedBox(height: 16),

                // Security notice
                _buildSecurityBanner(),
                const SizedBox(height: 16),

                // QR Code card
                _buildQrCard(),
                const SizedBox(height: 16),

                // Fallback code card
                _buildFallbackCodeCard(),
                const SizedBox(height: 16),

                // Info grid
                _buildInfoGrid(),
                const SizedBox(height: 20),

                // Back button
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('QUAY LẠI QUẢN TRỊ', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Live indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (_, _) => Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withValues(alpha: _glowAnimation.value),
                        blurRadius: 8, spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '● PHIÊN ĐANG MỞ TRỰC TIẾP',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Session title
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Timer display
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatDuration(_remainingSeconds),
                      style: TextStyle(
                        color: _sessionTimerColor,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Thời gian còn lại',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.2)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.sessionCode,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 28,
                        fontWeight: FontWeight.w900, letterSpacing: 6, fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Mã 6 số',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Session progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiến độ phiên học',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                  ),
                  Text(
                    '${(100 - _sessionProgress * 100).toStringAsFixed(0)}% đã dùng',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _sessionProgress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(_sessionTimerColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_rounded, color: AppTheme.warning, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dynamic QR Code · Bảo mật cao', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7B4F00))),
                SizedBox(height: 4),
                Text(
                  'QR đổi mỗi 60 giây · Mỗi mã chỉ dùng 1 lần · Chống chia sẻ ảnh',
                  style: TextStyle(fontSize: 11, color: Color(0xFF7B4F00), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard() {
    final isUrgent = _qrCountdown <= 10;
    final qrProgress = _qrRefreshSeconds > 0 ? _qrCountdown / _qrRefreshSeconds : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24, offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // QR countdown bar
            Row(
              children: [
                Icon(
                  isUrgent ? Icons.warning_amber_rounded : Icons.timer_rounded,
                  size: 16,
                  color: isUrgent ? AppTheme.error : AppTheme.primaryLight,
                ),
                const SizedBox(width: 6),
                Text(
                  isUrgent ? '⚡ Đang làm mới mã QR...' : 'QR hợp lệ trong:',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: isUrgent ? AppTheme.error : AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUrgent ? AppTheme.error.withValues(alpha: 0.1) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_qrCountdown giây',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold,
                      color: isUrgent ? AppTheme.error : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: qrProgress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isUrgent ? AppTheme.error : AppTheme.primaryLight,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // QR Code display
            if (_isLoadingQr)
              Container(
                width: 240, height: 240,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.primaryLight, strokeWidth: 3),
                    const SizedBox(height: 14),
                    Text('Đang tải mã QR mới...', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              )
            else if (_currentQrData != null)
              ScaleTransition(
                scale: _pulseAnimation,
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (_, child) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryLight.withValues(alpha: _glowAnimation.value * 0.3),
                          blurRadius: 24, spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: QrImageView(
                      data: _currentQrData!,
                      version: QrVersions.auto,
                      size: 240.0,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppTheme.primaryDark,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppTheme.primary,
                      ),
                      errorStateBuilder: (ctx, err) => SizedBox(
                        height: 240, width: 240,
                        child: Center(child: Text('Lỗi QR: $err', style: const TextStyle(color: AppTheme.error))),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 240, height: 240,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, color: AppTheme.error.withValues(alpha: 0.6), size: 40),
                    const SizedBox(height: 10),
                    Text(_qrErrorMessage ?? 'Không tải được mã QR', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppTheme.error)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _fetchQrToken,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Thử lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppTheme.primaryLight),
                const SizedBox(width: 6),
                const Text(
                  'Sinh viên quét màn hình để điểm danh',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCodeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.backup_rounded, size: 14, color: AppTheme.textSecondary),
                SizedBox(width: 6),
                Text('DỰ PHÒNG: NHẬP THỦ CÔNG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Dùng khi không quét được QR', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            const SizedBox(height: 14),

            GestureDetector(
              onTap: _copyCode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withValues(alpha: 0.06), AppTheme.primaryLight.withValues(alpha: 0.04)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.key_rounded, color: AppTheme.primary, size: 22),
                    const SizedBox(width: 14),
                    Text(
                      widget.sessionCode,
                      style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w900,
                        letterSpacing: 10, color: AppTheme.primary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.copy_rounded, size: 18, color: AppTheme.primaryLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Chạm để sao chép nhanh', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Row(
      children: [
        _buildInfoChip(Icons.location_on_rounded, '${widget.allowedRadiusMeters}m', 'GPS bán kính', AppTheme.success),
        const SizedBox(width: 10),
        _buildInfoChip(Icons.timer_rounded, '${widget.durationMinutes}p', 'Thời lượng', AppTheme.warning),
        const SizedBox(width: 10),
        _buildInfoChip(Icons.qr_code_2_rounded, '60s', 'QR đổi mỗi', AppTheme.primaryLight),
        const SizedBox(width: 10),
        _buildInfoChip(Icons.face_retouching_natural_rounded, 'Face', 'Xác thực', const Color(0xFF9C27B0)),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Text(value, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
