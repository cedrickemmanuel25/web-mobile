import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

class KycRejectedScreen extends ConsumerStatefulWidget {
  const KycRejectedScreen({super.key});

  @override
  ConsumerState<KycRejectedScreen> createState() => _KycRejectedScreenState();
}

class _KycRejectedScreenState extends ConsumerState<KycRejectedScreen> {

  Future<void> _contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@ivoirepay.ci',
      query: 'subject=Assistance KYC',
    );
    if (!await launchUrl(emailLaunchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le client email.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => context.go('/onboarding'), // Return to onboarding, will require login
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Lottie.network(
                  'https://lottie.host/17eb6ae8-cde8-48b4-b525-ee008fccdfd6/7E6X1D2pIq.json', // Sandbox Red X
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                     const Icon(Icons.error_outline, size: 80, color: Colors.red),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Dossier rejeté',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Motif du rejet :', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Les documents fournis sont illisibles ou incomplets. Veuillez vous assurer que les photos de votre pièce d\'identité sont nettes et non rognées.',
                      style: TextStyle(color: Colors.red, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.go('/kyc-wizard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Soumettre un nouveau dossier', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _contactSupport,
                icon: const Icon(Icons.help_outline, color: Colors.grey),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
                label: const Text('Contacter le support (support@ivoirepay.ci)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
