import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/phone_auth_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/setup_pin_screen.dart';
import '../../features/auth/screens/pin_login_screen.dart';
import '../../features/home/screens/home_wrapper_screen.dart';
import '../../features/payment/screens/scanner_screen.dart';
import '../../features/payment/screens/payment_screen.dart';
import '../../features/payment/screens/payment_success_screen.dart';
import '../../features/transactions/screens/transactions_screen.dart';
import '../../features/transactions/screens/transaction_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/change_pin_screen.dart';
import '../../features/kyc/screens/kyc_rejected_screen.dart';
import '../../features/kyc/screens/kyc_pending_screen.dart';
import '../../features/kyc/screens/kyc_wizard_screen.dart';
import '../../features/transactions/screens/merchant_transactions_screen.dart';
import '../../features/profile/screens/profile_wrapper_screen.dart';
import '../../features/home/screens/withdrawal_screen.dart';
import '../../features/home/screens/withdrawal_history_screen.dart';
import '../../features/home/screens/qr_code_full_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/phone-auth',
        builder: (context, state) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/pin-login',
        builder: (context, state) => const PinLoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeWrapperScreen(),
      ),
      GoRoute(
        path: '/setup-pin',
        builder: (context, state) => const SetupPinScreen(),
      ),
      GoRoute(
        path: '/kyc-wizard',
        builder: (context, state) => const KycWizardScreen(),
      ),
      GoRoute(
        path: '/kyc-pending',
        builder: (context, state) => const KycPendingScreen(),
      ),
      GoRoute(
        path: '/kyc-rejected',
        builder: (context, state) => const KycRejectedScreen(),
      ),
      GoRoute(
        path: '/withdrawal',
        builder: (context, state) => const WithdrawalScreen(),
      ),
      GoRoute(
        path: '/withdrawal-history',
        builder: (context, state) => const WithdrawalHistoryScreen(),
      ),
      GoRoute(
        path: '/merchant-transactions',
        builder: (context, state) => const MerchantTransactionsScreen(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final qrData = state.extra as Map<String, dynamic>? ?? {};
          return PaymentScreen(qrData: qrData);
        },
      ),
      GoRoute(
        path: '/payment-success',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return PaymentSuccessScreen(
            reference: data['reference'] ?? 'N/A',
            merchant: data['merchant'] ?? 'N/A',
            amount: (data['amount'] ?? 0).toDouble(),
          );
        },
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TransactionDetailScreen(transactionId: id);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileWrapperScreen(),
      ),
      GoRoute(
        path: '/qr-code-full',
        builder: (context, state) => const QrCodeFullScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/change-pin',
        builder: (context, state) => const ChangePinScreen(),
      ),
    ],
  );
}
