import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/transaction_service.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Transaction> _transactions = [];
  
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _selectedFilter = 'all';
  String? _error;

  final List<Map<String, String>> _filters = [
    {'id': 'all', 'label': 'Tous'},
    {'id': 'success', 'label': 'Réussies'},
    {'id': 'pending', 'label': 'En attente'},
    {'id': 'failed', 'label': 'Échouées'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchTransactions();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _transactions.clear();
    }

    if (!_hasMore || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(transactionServiceProvider);
      final newTx = await service.getTransactions(
        page: _currentPage,
        status: _selectedFilter,
      );

      if (mounted) {
        setState(() {
          _currentPage++;
          _transactions.addAll(newTx);
          if (newTx.length < 15) { // Assuming 15 items per page
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted && _transactions.isEmpty) {
        setState(() => _error = e.toString()); // Wait, to see the error let's print it to console
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: \${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onFilterChanged(String filterId) {
    if (_selectedFilter == filterId) return;
    setState(() => _selectedFilter = filterId);
    _fetchTransactions(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Mes Transactions', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter['id'];
                return GestureDetector(
                  onTap: () => _onFilterChanged(filter['id']!),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? green : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? green : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filter['label']!,
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Transactions List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchTransactions(refresh: true),
              color: green,
              child: _transactions.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _transactions.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _transactions.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator(color: green)),
                          );
                        }
                        return _buildTransactionTile(_transactions[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucune transaction trouvée',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Transaction tx) {
    Color walletColor;
    IconData walletIcon;

    switch (tx.walletType.toLowerCase()) {
      case 'wave':
        walletColor = const Color(0xFF1A73E8);
        walletIcon = Icons.waves;
        break;
      case 'djamo':
        walletColor = const Color(0xFF7C3AED);
        walletIcon = Icons.credit_card;
        break;
      case 'moov money':
      case 'moov':
        walletColor = const Color(0xFFE65100);
        walletIcon = Icons.phone_android;
        break;
      default:
        walletColor = Colors.grey;
        walletIcon = Icons.account_balance_wallet;
    }

    final dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => context.push('/transactions/${tx.id}'),
        leading: CircleAvatar(
          backgroundColor: walletColor.withOpacity(0.1),
          child: Icon(walletIcon, color: walletColor),
        ),
        title: Text(
          tx.merchantName,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$dateFormatted • ${tx.walletType}',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '-${tx.amount.toStringAsFixed(0)} XOF',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            _StatusBadge(status: tx.status),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'success':
      case 'réussie':
        color = Colors.green;
        label = 'Réussie';
        break;
      case 'failed':
      case 'échouée':
        color = Colors.red;
        label = 'Échouée';
        break;
      case 'pending':
      case 'processing':
      default:
        color = Colors.orange;
        label = 'En attente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
