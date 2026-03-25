import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'profile_screen.dart';
import 'merchant_profile_screen.dart';

class ProfileWrapperScreen extends ConsumerWidget {
  const ProfileWrapperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    if (user?.role == 'merchant') {
      return const MerchantProfileScreen();
    }
    
    return const ProfileScreen();
  }
}
