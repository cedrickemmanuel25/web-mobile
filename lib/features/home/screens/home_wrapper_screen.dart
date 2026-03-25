import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'client_home_screen.dart';
import 'merchant_home_screen.dart';

class HomeWrapperScreen extends ConsumerWidget {
  const HomeWrapperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    if (user?.role == 'merchant') {
      return const MerchantHomeScreen();
    }
    
    return const ClientHomeScreen();
  }
}
