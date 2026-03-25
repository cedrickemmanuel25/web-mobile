import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/pin_notifier.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_dots_row.dart';
import '../widgets/custom_keyboard.dart';
import '../widgets/user_avatar.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  @override
  void initState() {
    super.initState();
    // Reset PIN state every time the screen is opened to avoid pre-filled digits
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pinProvider.notifier).reset();
    });
  }

  Future<void> _loginWithBiometric() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (canAuthenticate) {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason:
              'Veuillez vous authentifier pour accéder à votre compte',
        );

        if (didAuthenticate && mounted) {
          context.go('/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biométrie non disponible')),
          );
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _onDigitTap(String digit) {
    final notifier = ref.read(pinProvider.notifier);
    notifier.addDigit(digit);

    final pinState = ref.read(pinProvider);
    if (pinState.enteredPin.length == 4) {
      _validatePin(pinState.enteredPin);
    }
  }

  Future<void> _validatePin(String pin) async {
    final authService = ref.read(authServiceProvider);
    final notifier = ref.read(pinProvider.notifier);

    try {
      final phone = await authService.getSavedPhone();
      if (phone == null) {
        notifier.reset();
        await authService.logout();
        if (mounted) context.go('/onboarding');
        return;
      }

      final success =
          await ref.read(authProvider.notifier).loginWithPin(phone, pin);

      if (success && mounted) {
        final user = ref.read(authProvider).user;

        if (user?.role == 'merchant') {
          final kycStatus = user?.kycStatus;
          if (kycStatus == 'approved') {
            context.go('/home');
          } else if (kycStatus == 'pending') {
            context.go('/kyc-pending');
          } else {
            context.go('/kyc-wizard');
          }
        } else {
          context.go('/home');
        }
      } else if (!success) {
        notifier.incrementFailure();
      }
    } catch (e) {
      notifier.incrementFailure();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinProvider);
    final authService = ref.read(authServiceProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: () async {
                    ref.read(pinProvider.notifier).reset();
                    await ref.read(authServiceProvider).logout();
                    if (mounted) context.go('/onboarding');
                  },
                  icon: const Icon(Icons.refresh, color: Color(0xFF1B4332)),
                  label: const Text('Recommencer',
                      style: TextStyle(color: Color(0xFF1B4332))),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<String?>(
              future: authService.getSavedUserName(),
              builder: (context, snapshot) {
                final name = snapshot.data ?? 'Utilisateur';
                return UserAvatar(name: name);
              },
            ),
            const SizedBox(height: 48),
            PinDotsRow(
              enteredDigits: pinState.enteredPin.length,
              hasError: pinState.error != null,
            ),
            if (pinState.error != null) ...[
              const SizedBox(height: 16),
              Text(
                pinState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w500),
              ),
            ],
            const Spacer(),
            if (!pinState.isLockedOut)
              CustomKeyboard(
                onDigitTap: _onDigitTap,
                onBackspace: () =>
                    ref.read(pinProvider.notifier).removeDigit(),
                onBiometric: _loginWithBiometric,
              )
            else
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.lock_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Compte suspendu',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Trop de tentatives échouées. Veuillez contacter le support technique pour débloquer votre compte.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4332),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Contacter le support'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
