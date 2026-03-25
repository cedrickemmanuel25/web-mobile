import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/providers/auth_provider.dart';

class KycPendingScreen extends ConsumerWidget {
  const KycPendingScreen({super.key});

  Future<void> _checkStatus(BuildContext context, WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);
    try {
      final statusMap = await authService.getKycStatus();
      if (statusMap != null) {
        final status = statusMap['kyc_status'];
        if (context.mounted) {
          if (status == 'approved') {
            final hasPin = statusMap['has_pin'] == true;
            if (!hasPin) {
              context.go('/setup-pin');
            } else {
              context.go('/pin-login');
            }
          } else if (status == 'rejected') {
            context.go('/kyc-rejected');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Votre demande est toujours en cours d\'examen.')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la vérification.')),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).logout();
    if (context.mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Lottie.network(
                  'https://lottie.host/8046b9a8-e125-46ff-a6f9-715bd0c1adcd/Gtd3xItiA4.json', // Sandbox hourglass
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                     const Icon(Icons.hourglass_empty, size: 80, color: Color(0xFF1B4332)),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Chip(
                  label: Text(
                    'En attente',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Votre dossier est en cours de vérification',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Notre équipe examine votre dossier. Vous recevrez un SMS dès sa validation (habituellement sous 24h à 48h).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => _checkStatus(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Vérifier le statut', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/kyc-wizard'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Modifier mon dossier', style: TextStyle(color: Color(0xFF1B4332))),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _logout(context, ref),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
