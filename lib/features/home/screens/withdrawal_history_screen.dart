import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/providers/auth_provider.dart';

class WithdrawalHistoryScreen extends ConsumerStatefulWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  ConsumerState<WithdrawalHistoryScreen> createState() => _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState extends ConsumerState<WithdrawalHistoryScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(authServiceProvider).getMerchantWithdrawals();
      if (res.statusCode == 200) {
        setState(() {
          _requests = res.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading withdrawal history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Historique des Retraits', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _requests.isEmpty
                ? const Center(child: Text('Aucun retrait effectué', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      final date = DateTime.parse(req['created_at']);
                      return _buildRequestCard(req, date);
                    },
                  ),
      ),
    );
  }

  Widget _buildRequestCard(dynamic req, DateTime date) {
    final status = req['status'] as String;
    final double amount = double.tryParse(req['amount']?.toString() ?? '0') ?? 0;
    final wallet = req['wallet_type'] as String;
    final number = req['wallet_number'] as String;

    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = 'En attente';
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusLabel = 'En cours';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusLabel = 'Terminé';
        break;
      case 'failed':
        statusColor = Colors.red;
        statusLabel = 'Échoué';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.outbox, color: statusColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${NumberFormat.decimalPattern().format(amount)} XOF',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('$wallet • $number', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                Text(DateFormat('dd MMM yyyy, HH:mm').format(date), style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
