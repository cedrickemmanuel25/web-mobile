import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  
  late final Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://ivoirepay-api-backend.loca.lt/api', // URL LocalTunnel fixe personnalisée
      headers: {
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Bypass-Tunnel-Reminder': 'true' // Requis par LocalTunnel pour laisser passer les APIs
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.addAll([
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    ]);
  }

  Future<Response> sendOtp(String phone, {String type = 'registration'}) async {
    return await _dio.post('/auth/send-otp', data: {
      'phone': phone,
      'type': type,
    });
  }

  Future<Response> verifyOtp(String phone, String code, {String type = 'registration'}) async {
    return await _dio.post('/auth/verify-otp', data: {
      'phone': phone,
      'code': code,
      'type': type,
    });
  }

  Future<Response> register({
    required String name,
    required String phone,
    required String role, // 'client' or 'merchant'
    Map<String, dynamic>? kycData,
  }) async {
    return await _dio.post('/auth/register', data: {
      'name': name,
      'phone': phone,
      'role': role,
      ...?kycData,
    });
  }

  Future<Response> setupPin(String pin) async {
    return await _dio.post('/auth/setup-pin', data: {
      'pin': pin,
      'pin_confirmation': pin,
    });
  }

  Future<Response> loginWithPin(String phone, String pin) async {
    return await _dio.post('/auth/login-pin', data: {
      'phone': phone,
      'pin': pin,
    });
  }

  Future<void> savePhone(String phone) async {
    await _storage.write(key: 'user_phone', value: phone);
  }

  Future<String?> getSavedPhone() async {
    return await _storage.read(key: 'user_phone');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> saveUserName(String name) async {
    await _storage.write(key: 'user_name', value: name);
  }

  Future<String?> getSavedUserName() async {
    return await _storage.read(key: 'user_name');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_phone');
  }

  Future<Response> initiateTransaction({
    required String merchantId,
    required double amount,
    required String walletType,
    required String walletNumber,
  }) async {
    return await _dio.post('/transactions/initiate', data: {
      'merchant_id': int.tryParse(merchantId) ?? 0,
      'amount': amount.toInt(),
      'wallet_type': walletType,
      'wallet_number': walletNumber,
    });
  }

  Future<Response> confirmTransaction(String txId, String pin, String walletNumber) async {
    return await _dio.post('/transactions/$txId/confirm', data: {
      'pin': pin,
      'wallet_number': walletNumber,
    });
  }

  Future<Response> changePin(String oldPin, String newPin) async {
    return await _dio.post('/auth/change-pin', data: {
      'current_pin': oldPin,
      'new_pin': newPin,
      'new_pin_confirmation': newPin,
    });
  }

  Future<Response> updateClientProfile({required String name, File? avatar}) async {
    final formData = FormData.fromMap({
      'name': name,
      if (avatar != null)
        'avatar': await MultipartFile.fromFile(avatar.path, filename: 'avatar.jpg'),
    });

    return await _dio.post('/profile/info', data: formData); // using POST for multipart
  }

  Future<User?> fetchUser() async {
    try {
      final res = await _dio.get('/user');
      if (res.statusCode == 200) {
        return User.fromJson(res.data);
      }
    } catch (_) {}
    return null;
  }

  Future<Response> submitKyc(
    Map<String, dynamic> data,
    List<File> documents,
    List<String> documentTypes,
  ) async {
    final formDataMap = <String, dynamic>{...data};

    // Backend expects: documents[] (files array) + document_types[] (strings array)
    final List<MultipartFile> multipartFiles = [];
    for (final file in documents) {
      multipartFiles.add(await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ));
    }
    formDataMap['documents[]'] = multipartFiles;
    formDataMap['document_types[]'] = documentTypes;

    final formData = FormData.fromMap(formDataMap);
    return await _dio.post('/merchant/kyc/submit', data: formData);
  }

  Future<Map<String, dynamic>?> getKycStatus() async {
    try {
      final res = await _dio.get('/merchant/kyc/status');
      if (res.statusCode == 200) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getMerchantDashboard() async {
    try {
      final res = await _dio.get('/merchant/dashboard');
      if (res.statusCode == 200) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> getMerchantQrCode() async {
    try {
      final res = await _dio.get('/merchant/qr-code');
      if (res.statusCode == 200) {
        return res.data['qr_code_url'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getMerchantProfile() async {
    try {
      final res = await _dio.get('/merchant/profile');
      if (res.statusCode == 200) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ─── Merchant Transactions & Withdrawals ──────────────────────────────────
  
  Future<Response> getMerchantTransactions({String? filter}) async {
    return await _dio.get('/merchant/transactions', queryParameters: {
      if (filter != null) 'filter': filter,
    });
  }

  Future<Response> getMerchantWithdrawals() async {
    return await _dio.get('/merchant/withdrawals');
  }

  Future<Response> submitWithdrawal({
    required double amount,
    required String walletType,
    required String walletNumber,
  }) async {
    return await _dio.post('/merchant/withdrawal', data: {
      'amount': amount,
      'wallet_type': walletType,
      'wallet_number': walletNumber,
    });
  }
}
