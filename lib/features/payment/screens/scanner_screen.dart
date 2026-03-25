import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _torchOn = false;
  bool _scanned = false;
  late AnimationController _animController;
  late Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    try {
      final qrData = jsonDecode(barcode!.rawValue!) as Map<String, dynamic>;
      if (qrData['type'] == 'static_qr') {
        setState(() => _scanned = true);
        _controller.stop();
        context.push('/payment', extra: qrData);
      } else {
        _showError('QR Code non reconnu par IvoirePay');
      }
    } catch (_) {
      _showError('QR Code invalide');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _scanned = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Dark overlay with transparent scan area
          _buildOverlay(),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Scanner un QR Code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Centrez le QR Code du commerçant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                      label: 'Lampe',
                      onTap: () async {
                        await _controller.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    const scanBoxSize = 260.0;

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final left = (width - scanBoxSize) / 2;
      final top = (height - scanBoxSize) / 2 - 40;

      return Stack(
        children: [
          // Dark overlay - top
          Positioned(
            top: 0, left: 0, right: 0,
            height: top,
            child: Container(color: Colors.black.withOpacity(0.7)),
          ),
          // Dark overlay - bottom
          Positioned(
            top: top + scanBoxSize, left: 0, right: 0, bottom: 0,
            child: Container(color: Colors.black.withOpacity(0.7)),
          ),
          // Dark overlay - left
          Positioned(
            top: top, left: 0,
            width: left, height: scanBoxSize,
            child: Container(color: Colors.black.withOpacity(0.7)),
          ),
          // Dark overlay - right
          Positioned(
            top: top, right: 0,
            width: left, height: scanBoxSize,
            child: Container(color: Colors.black.withOpacity(0.7)),
          ),
          // Scan box border corners (amber)
          Positioned(
            top: top, left: left,
            width: scanBoxSize, height: scanBoxSize,
            child: _buildScanBox(scanBoxSize),
          ),
          // Animated scan line
          Positioned(
            top: top,
            left: left,
            width: scanBoxSize,
            height: scanBoxSize,
            child: AnimatedBuilder(
              animation: _scanLineAnim,
              builder: (_, __) => Stack(
                children: [
                  Positioned(
                    top: _scanLineAnim.value * (scanBoxSize - 4),
                    left: 8,
                    right: 8,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.withOpacity(0),
                            Colors.amber,
                            Colors.amber.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildScanBox(double size) {
    const cornerLen = 30.0;
    const thickness = 3.5;
    const color = Colors.amber;
    const radius = 12.0;

    return CustomPaint(
      painter: _CornerPainter(
        cornerLen: cornerLen,
        thickness: thickness,
        color: color,
        radius: radius,
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double cornerLen;
  final double thickness;
  final Color color;
  final double radius;

  _CornerPainter({
    required this.cornerLen,
    required this.thickness,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final corners = [
      // top-left
      [Offset(0, cornerLen), Offset(0, radius), Offset(radius, 0), Offset(cornerLen, 0)],
      // top-right
      [Offset(size.width - cornerLen, 0), Offset(size.width - radius, 0), Offset(size.width, radius), Offset(size.width, cornerLen)],
      // bottom-left
      [Offset(0, size.height - cornerLen), Offset(0, size.height - radius), Offset(radius, size.height), Offset(cornerLen, size.height)],
      // bottom-right
      [Offset(size.width - cornerLen, size.height), Offset(size.width - radius, size.height), Offset(size.width, size.height - radius), Offset(size.width, size.height - cornerLen)],
    ];

    for (final c in corners) {
      canvas.drawLine(c[0], c[1], paint);
      canvas.drawLine(c[2], c[3], paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}
