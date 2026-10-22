import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

/// Widget nhập mã PIN/OTP gồm N ô (mặc định 6 ô)
/// Hỗ trợ: tự động focus, animate khi nhập, haptic feedback
class PinCodeField extends StatelessWidget {
  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  const PinCodeField({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final text = controller.text;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Invisible text field để handle keyboard và input
            Opacity(
              opacity: 0.0,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: length,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  onChanged?.call(val);
                  if (val.length == length) {
                    onCompleted?.call(val);
                  }
                },
              ),
            ),

            // Custom PIN boxes UI
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(length, (index) {
                final isFilled = index < text.length;
                final isFocused = index == text.length && index < length;
                final char = isFilled ? (obscureText ? '●' : text[index]) : '';

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 48,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: isFilled
                        ? AppTheme.primary.withValues(alpha: 0.06)
                        : (isFocused ? Colors.white : const Color(0xFFF5F7FF)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isFocused
                          ? AppTheme.primary
                          : (isFilled ? AppTheme.primaryLight.withValues(alpha: 0.5) : AppTheme.border),
                      width: isFocused ? 2.2 : 1.5,
                    ),
                    boxShadow: isFocused
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ]
                        : isFilled
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                  ),
                  alignment: Alignment.center,
                  child: isFocused && char.isEmpty
                      ? _buildCursor()
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: Text(
                            char,
                            key: ValueKey(char),
                            style: TextStyle(
                              fontSize: obscureText ? 18 : 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCursor() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (_, value, _) => AnimatedOpacity(
        opacity: value > 0.5 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 2,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
