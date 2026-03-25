import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});

class TransactionService {
  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  TransactionService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://ivoirepay-api-backend.loca.lt/api',
      headers: {
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Bypass-Tunnel-Reminder': 'true'
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<List<Transaction>> getTransactions({int page = 1, String? status}) async {
    final Map<String, dynamic> query = {'page': page};
    if (status != null && status != 'all') {
      query['status'] = status;
    }
    
    final response = await _dio.get('/transactions', queryParameters: query);
    final data = response.data['data'] as List;
    return data.map((json) => Transaction.fromJson(json)).toList();
  }

  Future<Transaction> getTransactionDetails(String id) async {
    final response = await _dio.get('/transactions/$id');
    return Transaction.fromJson(response.data);
  }

  Future<File?> downloadReceipt(String id, String reference) async {
    try {
      final response = await _dio.get(
        '/transactions/$id/receipt',
        options: Options(responseType: ResponseType.bytes),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('\${dir.path}/ivoirepay_receipt_\$reference.pdf');
      
      await file.writeAsBytes(response.data);
      return file;
    } catch (e) {
      return null;
    }
  }
}
