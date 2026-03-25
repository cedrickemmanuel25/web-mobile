import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  late Timer _timer;
  int _secondsRemaining = 300; // 5 minutes
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
          _timer.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _onVerify(String code) async {
    final success = await ref.read(authProvider.notifier).verifyOtp(code);
    if (success && mounted) {
      final authState = ref.read(authProvider);
      if (authState.isRegistered && authState.user != null) {
        final user = authState.user!;
        debugPrint('OtpScreen: Navigating existing user. Role=${user.role}, HasPin=${user.hasPin}, KYC=${user.kycStatus}');
        
        if (user.role == 'merchant') {
          final kycStatus = user.kycStatus;
          
          if (kycStatus == 'pending') {
            context.go('/kyc-pending');
          } else if (kycStatus == 'rejected') {
            context.go('/kyc-rejected');
          } else if (kycStatus == null || kycStatus == 'unsubmitted' || kycStatus.isEmpty) {
            context.go('/kyc-wizard');
          } else if (kycStatus == 'approved') {
            if (!user.hasPin) {
              context.go('/setup-pin');
            } else {
              context.go('/pin-login');
            }
          } else {
            // Fallback for unexpected status
            if (!user.hasPin) {
              context.go('/setup-pin');
            } else {
              context.go('/pin-login');
            }
          }
        } else {
          // Client
          if (!user.hasPin) {
            context.go('/setup-pin');
          } else {
            context.go('/pin-login');
          }
        }
      } else {
        context.push('/register');
      }
    }
  }

  void _resendCode() async {
    if (!_canResend) return;
    
    final phone = ref.read(authProvider).phoneNumber;
    if (phone != null) {
      final success = await ref.read(authProvider.notifier).sendOtp(phone);
      if (success) {
        setState(() {
          _secondsRemaining = 300;
          _canResend = false;
        });
        _startTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final phone = authState.phoneNumber ?? '';
    final maskedPhone = phone.length >= 10 
        ? '+225 ${phone.substring(0, 2)} *** *** ${phone.substring(8)}'
        : phone;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFF1B4332), width: 2),
      color: Colors.white,
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: const Color(0xFF1B4332).withOpacity(0.05),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Code de vérification',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Entrez le code envoyé au $maskedPhone',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              Center(
                child: Pinput(
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  onCompleted: _onVerify,
                  autofocus: true,
                ),
              ),
              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: _secondsRemaining / 300,
                            strokeWidth: 4,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B4332)),
                          ),
                        ),
                        Text(
                          _formatTime(_secondsRemaining),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _canResend ? _resendCode : null,
                      child: Text(
                        'Renvoyer le code',
                        style: TextStyle(
                          color: _canResend ? const Color(0xFF1B4332) : Colors.grey,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (authState.error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      authState.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              if (authState.isLoading)
                const Center(child: CircularProgressIndicator(color: Color(0xFF1B4332))),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
