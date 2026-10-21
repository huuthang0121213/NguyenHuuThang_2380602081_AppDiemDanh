import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinCodeField extends StatelessWidget {
  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;

  const PinCodeField({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
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
            // Invisible actual text field to handle focus and keyboard input cleanly
            Opacity(
              opacity: 0.0,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: length,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (val) {
                  onChanged?.call(val);
                  if (val.length == length) {
                    onCompleted?.call(val);
                  }
                },
              ),
            ),
            // Custom modern 6-box UI
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(length, (index) {
                final isFilled = index < text.length;
                final isFocused = index == text.length;
                final char = isFilled ? text[index] : '';

                return Container(
                  width: 44,
                  height: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isFilled
                        ? const Color(0xFFEFF6FF)
                        : (isFocused ? Colors.white : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFocused
                          ? const Color(0xFF2563EB)
                          : (isFilled ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1)),
                      width: isFocused ? 2.0 : 1.2,
                    ),
                    boxShadow: isFocused
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    char,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                      fontFamily: 'monospace',
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
}
