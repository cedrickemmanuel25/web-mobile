import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:dio/dio.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final token = await _storage.read(key: 'auth_token');

    if (token == null) {
      if (mounted) context.go('/onboarding');
      return;
    }

    // Validate the token against the backend
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://ivoirepay-api-backend.loca.lt/api',
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
          'Bypass-Tunnel-Reminder': 'true'
        },
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.get('/user');
      debugPrint('SplashScreen: User Data received: ${response.data}');

      // Save the user name locally for display
      final name = response.data['name'];
      if (name != null && name.toString().isNotEmpty) {
        await _storage.write(key: 'user_name', value: name.toString());
      }

      final role = response.data['role'];
      final kycStatus = response.data['kyc_status'];
      final hasPin = response.data['has_pin'] == true;
      
      debugPrint('SplashScreen: Role=$role, KYC=$kycStatus, HasPin=$hasPin');

      if (role == 'merchant') {
        if (kycStatus == 'pending') {
          if (mounted) context.go('/kyc-pending');
          return;
        } else if (kycStatus == 'rejected') {
          if (mounted) context.go('/kyc-rejected');
          return;
        } else if (kycStatus == 'approved') {
          // After approval, merchant must set up PIN before accessing home
          final hasPin = response.data['has_pin'] == true;
          if (!hasPin) {
            if (mounted) context.go('/setup-pin');
          } else {
            if (mounted) context.go('/pin-login');
          }
          return;
        } else {
          // If null, unsubmitted, or any other status for a merchant
          if (mounted) context.go('/kyc-wizard');
          return;
        }
      }

      // Client with valid token → PIN login
      if (mounted) context.go('/pin-login');
    } on DioException catch (e) {
      debugPrint('SplashScreen: Error during token validation: ${e.message}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        // Token invalid/expired or user deleted — clear everything
        debugPrint('SplashScreen: Token invalid or User not found (401/404). Clearing storage.');
        await _storage.deleteAll();
        if (mounted) context.go('/onboarding');
      } else {
        // Network error or other server error — still has a token, try PIN login
        debugPrint('SplashScreen: Network or Server error. Status: ${e.response?.statusCode}. Proceeding to PIN login.');
        if (mounted) context.go('/pin-login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B4332),
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 200,
            )
                .animate()
                .fade(duration: 800.ms)
                .scale(
                  duration: 800.ms,
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                ),
          ),
          const Positioned(
            bottom: 50,
            left: 50,
            right: 50,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  color: Colors.amber,
                  backgroundColor: Colors.white24,
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'v1.0.5-debug',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
