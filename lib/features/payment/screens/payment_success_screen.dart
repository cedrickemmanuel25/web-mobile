import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String reference;
  final String merchant;
  final double amount;

  const PaymentSuccessScreen({
    super.key,
    required this.reference,
    required this.merchant,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year} à ${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),

              // Success animation
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4332).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF1B4332),
                    size: 90,
                  ),
                ),
              )
                  .animate()
                  .scale(delay: 100.ms, duration: 600.ms, curve: Curves.elasticOut)
                  .fade(duration: 400.ms),

              const SizedBox(height: 24),

              Text(
                'Paiement réussi !',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B4332),
                ),
              ).animate().slideY(begin: 0.3, duration: 400.ms, delay: 300.ms).fade(),

              const SizedBox(height: 8),

              Text(
                '${amount.toStringAsFixed(0)} XOF',
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 40),

              // Receipt card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _receiptRow('Référence', reference),
                    const Divider(height: 20),
                    _receiptRow('Commerçant', merchant),
                    const Divider(height: 20),
                    _receiptRow('Montant', '${amount.toStringAsFixed(0)} XOF'),
                    const Divider(height: 20),
                    _receiptRow('Date', dateStr),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

              const Spacer(),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareReceipt(reference, merchant, amount, dateStr),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Partager'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B4332),
                        side: const BorderSide(color: Color(0xFF1B4332)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.home, size: 18),
                      label: const Text('Accueil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4332),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _shareReceipt(String ref, String merchant, double amount, String date) {
    final text = '''
🎉 Paiement IvoirePay réussi !

📇 Référence: $ref
🏪 Commerçant: $merchant
💰 Montant: ${amount.toStringAsFixed(0)} XOF
📅 Date: $date

Paiement sécurisé via IvoirePay 🔒
''';
    Share.share(text, subject: 'Reçu de paiement IvoirePay');
  }
}
