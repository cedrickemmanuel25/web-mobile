import 'package:flutter/material.dart';

class CustomKeyboard extends StatefulWidget {
  final Function(String) onDigitTap;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  const CustomKeyboard({
    super.key,
    required this.onDigitTap,
    required this.onBackspace,
    this.onBiometric,
  });

  @override
  State<CustomKeyboard> createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  late List<String> _digits;

  @override
  void initState() {
    super.initState();
    _digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
    _digits.shuffle();
  }

  Widget _buildButton(String text, {VoidCallback? onTap, IconData? icon, Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () => widget.onDigitTap(text),
            borderRadius: BorderRadius.circular(40),
            child: Container(
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color ?? Colors.grey.shade50,
              ),
              child: icon != null 
                  ? Icon(icon, size: 28, color: Colors.black)
                  : Text(
                      text,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildButton(_digits[0]),
            _buildButton(_digits[1]),
            _buildButton(_digits[2]),
          ],
        ),
        Row(
          children: [
            _buildButton(_digits[3]),
            _buildButton(_digits[4]),
            _buildButton(_digits[5]),
          ],
        ),
        Row(
          children: [
            _buildButton(_digits[6]),
            _buildButton(_digits[7]),
            _buildButton(_digits[8]),
          ],
        ),
        Row(
          children: [
            widget.onBiometric != null 
                ? _buildButton('', icon: Icons.fingerprint, onTap: widget.onBiometric!)
                : const Expanded(child: SizedBox()),
            _buildButton(_digits[9]),
            _buildButton('', icon: Icons.backspace_outlined, onTap: widget.onBackspace),
          ],
        ),
      ],
    );
  }
}
