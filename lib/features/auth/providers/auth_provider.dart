import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthState {
  final bool isLoading;
  final String? error;
  final String? phoneNumber;
  final bool isOtpSent;
  final bool isRegistered;
  final User? user;

  AuthState({
    this.isLoading = false,
    this.error,
    this.phoneNumber,
    this.isOtpSent = false,
    this.isRegistered = false,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? phoneNumber,
    bool? isOtpSent,
    bool? isRegistered,
    User? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isRegistered: isRegistered ?? this.isRegistered,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  AuthService get _authService => ref.read(authServiceProvider);

  Future<bool> sendOtp(String phone, {String type = 'registration'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.sendOtp(phone, type: type);
      if (response.statusCode == 200) {
        await _authService.savePhone(phone);
        state = state.copyWith(isLoading: false, isOtpSent: true, phoneNumber: phone);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Erreur lors de l\'envoi de l\'OTP');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return false;
    }
  }

  Future<bool> verifyOtp(String code, {String type = 'registration'}) async {
    if (state.phoneNumber == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.verifyOtp(state.phoneNumber!, code, type: type);
      if (response.statusCode == 200) {
        final token = response.data['token'];
        final isNewUser = response.data['is_new_user'] ?? false;
        if (token != null) {
          await _authService.saveToken(token);
        }
        final userData = response.data['user'];
        User? user;
        if (userData != null) {
          user = User.fromJson(userData);
          // NEW: Save name immediately if available
          if (user.name.isNotEmpty) {
            await _authService.saveUserName(user.name);
          }
        }

        // IMPORTANT: Fetch deep profile to ensure we have latest kycStatus and hasPin
        final deepUser = await _authService.fetchUser();
        if (deepUser != null) {
          user = deepUser;
          if (user.name.isNotEmpty) {
            await _authService.saveUserName(user.name);
          }
        }
        
        debugPrint('AuthNotifier: verifyOtp Success. Role=${user?.role}, KYC=${user?.kycStatus}, HasPin=${user?.hasPin}');

        state = state.copyWith(
          isLoading: false, 
          isRegistered: !isNewUser,
          user: user,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Code incorrect');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String role,
    Map<String, dynamic>? kycData,
  }) async {
    if (state.phoneNumber == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.register(
        name: name,
        phone: state.phoneNumber!,
        role: role,
        kycData: kycData,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = response.data['token'];
        if (token != null) {
          await _authService.saveToken(token);
        }
        final userData = response.data['user'];
        User? user;
        if (userData != null) {
          user = User.fromJson(userData);
          // NEW: Save name immediately
          if (user.name.isNotEmpty) {
            await _authService.saveUserName(user.name);
          }
        }

        // Refresh to get full state
        final deepUser = await _authService.fetchUser();
        if (deepUser != null) {
          user = deepUser;
          if (user.name.isNotEmpty) {
            await _authService.saveUserName(user.name);
          }
        }

        debugPrint('AuthNotifier: register Success. Role=${user?.role}, KYC=${user?.kycStatus}, HasPin=${user?.hasPin}');
        
        state = state.copyWith(isLoading: false, isRegistered: true, user: user);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Erreur lors de l\'inscription');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return false;
    }
  }

  Future<bool> loginWithPin(String phone, String pin) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.loginWithPin(phone, pin);
      if (response.statusCode == 200) {
        final token = response.data['token'];
        if (token != null) {
          await _authService.saveToken(token);
        }

        final userData = response.data['user'];
        if (userData != null) {
          final user = User.fromJson(userData);
          if (user.name.isNotEmpty) {
            await _authService.saveUserName(user.name);
          }
        }
        
        // Fetch full profile to get role and KYC status
        final user = await _authService.fetchUser();
        if (user != null) {
          if (user.name.isNotEmpty) {
            await _authService.saveUserName(user.name);
          }
          state = state.copyWith(isLoading: false, user: user);
          return true;
        }
      }
      state = state.copyWith(isLoading: false, error: 'PIN incorrect');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return false;
    }
  }

  Future<void> fetchUser() async {
    try {
      final user = await _authService.fetchUser();
      if (user != null) {
        state = state.copyWith(user: user);
      }
    } catch (e) {
      debugPrint('AuthNotifier: fetchUser Error: $e');
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }

  String _getErrorMessage(Object e) {
    if (e is DioException) {
      final de = e;
      switch (de.type) {
        case DioExceptionType.connectionTimeout:
          return 'Délai de connexion dépassé. Vérifiez votre URL/Serveur.';
        case DioExceptionType.receiveTimeout:
          return 'Le serveur ne répond pas (Timeout de réception).';
        case DioExceptionType.sendTimeout:
          return 'Erreur d\'envoi au serveur.';
        case DioExceptionType.badResponse:
          final status = de.response?.statusCode;
          if (status == 401) return 'Identifiants (PIN/OTP) incorrects.';
          if (status == 404) return 'Resource ou utilisateur introuvable.';
          if (status == 422) return de.response?.data['message'] ?? 'Données invalides.';
          if (status == 429) return 'Trop de tentatives. Réessayez plus tard.';
          return 'Erreur serveur ($status).';
        case DioExceptionType.connectionError:
          return 'Impossible de contacter le serveur. Vérifiez votre connexion.';
        default:
          return 'Erreur réseau inattendue.';
      }
    }
    return 'Une erreur est survenue: $e';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
