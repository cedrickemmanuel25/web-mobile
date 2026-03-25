import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/auth_service.dart';

class QrCodeFullScreen extends ConsumerStatefulWidget {
  const QrCodeFullScreen({super.key});

  @override
  ConsumerState<QrCodeFullScreen> createState() => _QrCodeFullScreenState();
}

class _QrCodeFullScreenState extends ConsumerState<QrCodeFullScreen> {
  String? _qrUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQr();
  }

  Future<void> _loadQr() async {
    final url = await ref.read(authServiceProvider).getMerchantQrCode();
    if (mounted) {
      setState(() {
        _qrUrl = url;
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPng() async {
    if (_qrUrl == null) return;
    // For now we just download the SVG as file since the backend produces SVG
    try {
      final res = await http.get(Uri.parse(_qrUrl!));
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/ivoirepay_qr.svg');
      await file.writeAsBytes(res.bodyBytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('QR Code sauvegardé dans: ${file.path}')));
      }
    } catch (e) {
      _showError('Échec du téléchargement');
    }
  }

  Future<void> _shareQr() async {
    if (_qrUrl == null) return;
    try {
      final res = await http.get(Uri.parse(_qrUrl!));
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/qr_share.svg';
      await File(path).writeAsBytes(res.bodyBytes);
      await Share.shareXFiles([XFile(path)], text: 'Scannez mon QR Code IvoirePay !');
    } catch (e) {
      _showError('Échec du partage');
    }
  }

  Future<void> _printQr() async {
    if (_qrUrl == null) return;
    try {
      final res = await http.get(Uri.parse(_qrUrl!));
      final doc = pw.Document();
      final svgRaw = res.body;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Payer avec IvoirePay', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    width: 400,
                    height: 400,
                    child: pw.SvgImage(svg: svgRaw),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(ref.read(authProvider).user?.name ?? 'Commerçant', style: pw.TextStyle(fontSize: 18)),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
    } catch (e) {
      _showError('Échec de l\'impression: $e');
    }
  }

  void _showError(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final businessName = ref.watch(authProvider).user?.name ?? 'Commerçant';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const CloseButton(color: Colors.black),
        title: Text('Mon QR Code', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 10))
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: _qrUrl != null 
                    ? SvgPicture.network(_qrUrl!, fit: BoxFit.contain)
                    : const Icon(Icons.error_outline, size: 40),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                businessName,
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                child: Text(
                  'Faites scanner ce QR code par vos clients pour recevoir un paiement instantané.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.print,
                        label: 'Imprimer',
                        onTap: _printQr,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.download,
                        label: 'PNG',
                        onTap: _downloadPng,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.share,
                        label: 'Partager',
                        isPrimary: true,
                        onTap: _shareQr,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFF1B4332) : Colors.grey.shade100,
        foregroundColor: isPrimary ? Colors.white : Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
