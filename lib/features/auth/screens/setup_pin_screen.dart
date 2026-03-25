import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/pin_notifier.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_dots_row.dart';
import '../widgets/custom_keyboard.dart';

class SetupPinScreen extends ConsumerStatefulWidget {
  const SetupPinScreen({super.key});

  @override
  ConsumerState<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends ConsumerState<SetupPinScreen> {
  
  void _onDigitTap(String digit) async {
    final notifier = ref.read(pinProvider.notifier);
    notifier.addDigit(digit);
    
    final state = ref.read(pinProvider);
    if (state.enteredPin.length == 4) {
      if (!state.isConfirming) {
        // Step 1 done, move to confirmation
        await Future.delayed(const Duration(milliseconds: 300));
        notifier.startConfirmation();
      } else {
        // Step 2 done, verify matching
        if (state.enteredPin == state.confirmedPin) {
          _completeSetup(state.enteredPin);
        } else {
          // No match
          notifier.reset();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les codes PIN ne correspondent pas. Réessayez.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _completeSetup(String pin) async {
    final authService = ref.read(authServiceProvider);
    try {
      final response = await authService.setupPin(pin);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          // PIN setup finishes onboarding for both clients and approved merchants
          context.go('/home');
        }
      } else {
        _showError('Erreur lors de la configuration du PIN');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: pinState.isConfirming ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => ref.read(pinProvider.notifier).reset(),
        ) : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                pinState.isConfirming ? 'Confirmez votre PIN' : 'Créez votre PIN de sécurité',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                pinState.isConfirming 
                    ? 'Entrez à nouveau votre code à 4 chiffres' 
                    : 'Ce code sera utilisé pour vos futurs paiements',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 60),
              PinDotsRow(enteredDigits: pinState.enteredPin.length),
              const SizedBox(height: 48),
              CustomKeyboard(
                onDigitTap: _onDigitTap,
                onBackspace: () => ref.read(pinProvider.notifier).removeDigit(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
