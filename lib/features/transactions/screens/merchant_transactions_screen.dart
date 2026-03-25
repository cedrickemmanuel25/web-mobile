import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/providers/auth_provider.dart';

class MerchantTransactionsScreen extends ConsumerStatefulWidget {
  const MerchantTransactionsScreen({super.key});

  @override
  ConsumerState<MerchantTransactionsScreen> createState() => _MerchantTransactionsScreenState();
}

class _MerchantTransactionsScreenState extends ConsumerState<MerchantTransactionsScreen> {
  String _selectedFilter = 'Tous';
  List<dynamic> _transactions = [];
  List<dynamic> _chartData = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);
    
    try {
      // Load dashboard for chart data
      final dashboardRes = await authService.getMerchantDashboard();
      if (dashboardRes != null) {
        _chartData = dashboardRes['chart_data'] ?? [];
      }

      // Load transactions
      String? backendFilter;
      if (_selectedFilter == 'Aujourd\'hui') backendFilter = 'today';
      if (_selectedFilter == 'Cette semaine') backendFilter = 'week';
      if (_selectedFilter == 'Ce mois') backendFilter = 'month';

      final transRes = await authService.getMerchantTransactions(filter: backendFilter);
      if (transRes.statusCode == 200) {
        setState(() {
          _transactions = transRes.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading merchant transactions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mes Revenus', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChartSection(),
              _buildFilterSection(),
              _buildTransactionsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    if (_chartData.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenus (7 derniers jours)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartData.asMap().entries.map((e) {
                      final double revenue = double.tryParse(e.value['revenue']?.toString() ?? '0') ?? 0;
                      return FlSpot(e.key.toDouble(), revenue);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF1B4332),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1B4332).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final filters = ['Tous', 'Aujourd\'hui', 'Cette semaine', 'Ce mois'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedFilter = filter);
                  _loadData();
                }
              },
              selectedColor: const Color(0xFF1B4332),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              backgroundColor: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    }

    if (_transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('Aucune transaction trouvée', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final double amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
        final client = tx['client'];
        final date = DateTime.parse(tx['created_at']);
        final status = tx['status'];
        final wallet = tx['wallet_type'];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1B4332).withOpacity(0.1),
              child: const Icon(Icons.call_received, color: Color(0xFF1B4332)),
            ),
            title: Text(client != null ? client['name'] ?? 'Inconnu' : 'Client Inconnu', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm').format(date)} • ${wallet?.toUpperCase()}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+ ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(amount)} XOF',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  status == 'completed' ? 'Succès' : status,
                  style: TextStyle(
                    fontSize: 12,
                    color: status == 'completed' ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
