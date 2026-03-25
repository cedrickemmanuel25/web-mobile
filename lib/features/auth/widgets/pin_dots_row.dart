import 'package:flutter/material.dart';

class PinDotsRow extends StatelessWidget {
  final int enteredDigits;
  final int totalDigits;
  final bool hasError;

  const PinDotsRow({
    super.key,
    required this.enteredDigits,
    this.totalDigits = 4,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDigits, (index) {
        final isFilled = index < enteredDigits;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled 
                ? (hasError ? Colors.red : const Color(0xFF1B4332)) 
                : Colors.grey.shade200,
            border: Border.all(
              color: isFilled 
                  ? (hasError ? Colors.red : const Color(0xFF1B4332)) 
                  : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }
}
