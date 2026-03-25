import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/custom_keyboard.dart';
import '../../auth/widgets/pin_dots_row.dart';

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _walletNumberController = TextEditingController();
  String _selectedWallet = 'wave';
  double _balance = 0.0;
  bool _isLoading = true;
  final double _commissionRate = 0.01; // 1% commission
  final double _minWithdrawal = 1000.0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final dashboard = await ref.read(authServiceProvider).getMerchantDashboard();
    if (dashboard != null) {
      if (mounted) {
        setState(() {
          _balance = double.tryParse(dashboard['balance']?.toString() ?? '0') ?? 0.0;
          _isLoading = false;
        });
      }
    }
  }

  void _showPinConfirmation() {
    final amountText = _amountController.text;
    final walletNumber = _walletNumberController.text;

    if (amountText.isEmpty || walletNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount < _minWithdrawal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le montant minimum est de ${NumberFormat.decimalPattern().format(_minWithdrawal)} XOF')),
      );
      return;
    }

    if (amount > _balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solde insuffisant')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _PinConfirmationSheet(
        onSuccess: (pin) => _submitWithdrawal(amount, walletNumber),
      ),
    );
  }

  Future<void> _submitWithdrawal(double amount, String walletNumber) async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(authServiceProvider).submitWithdrawal(
        amount: amount,
        walletType: _selectedWallet,
        walletNumber: walletNumber,
      );

      if (res.statusCode == 201) {
        if (mounted) {
          context.pop(); // Close sheet
          _showSuccessDialog();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message'] ?? 'Erreur lors du retrait')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Une erreur est survenue')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Demande envoyée !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Votre demande de retrait est en cours de traitement.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.pop();
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retour à l\'accueil', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    double receivedAmount = amount - (amount * _commissionRate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Retrait de fonds', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/withdrawal-history'),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceHeader(),
                  const SizedBox(height: 32),
                  const Text('Montant à retirer', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Min. 1 000 XOF',
                      suffixText: 'XOF',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Méthode de réception', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildWalletSelector(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _walletNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Numéro de téléphone du wallet',
                      prefixIcon: const Icon(Icons.phone_iphone),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSummary(receivedAmount),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _showPinConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4332),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Demander le retrait', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('Solde disponible', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${NumberFormat.decimalPattern().format(_balance)} XOF',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSelector() {
    final wallets = [
      {'id': 'wave', 'name': 'Wave', 'color': const Color(0xFF2196F3), 'logo': 'assets/images/wave.jpg'},
      {'id': 'orange', 'name': 'Orange', 'color': const Color(0xFFFF6D00), 'logo': 'assets/images/orange.jpg'},
      {'id': 'mtn', 'name': 'MTN', 'color': const Color(0xFFFDD835), 'logo': 'assets/images/mtn.jpg'},
      {'id': 'djamo', 'name': 'Djamo', 'color': const Color(0xFF673AB7), 'logo': 'assets/images/djamo.jpg'},
      {'id': 'moov', 'name': 'Moov', 'color': const Color(0xFFFF9800), 'logo': 'assets/images/moov.png'},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: wallets.map((w) {
        final isSelected = _selectedWallet == w['id'];
        final color = w['color'] as Color;
        final size = (MediaQuery.of(context).size.width - 68) / 3; // Approx 3 per row
        
        return GestureDetector(
          onTap: () => setState(() => _selectedWallet = w['id'] as String),
          child: Container(
            width: size,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.05) : Colors.white,
              border: Border.all(
                color: isSelected ? color : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected ? [
                BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
              ] : null,
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    w['logo'] as String,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.account_balance_wallet, 
                      color: isSelected ? color : Colors.grey,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  w['name'] as String, 
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? color : Colors.black87, 
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummary(double received) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber[200]!)),
      child: Column(
        children: [
          _summaryRow('Frais de service (1%)', '- ${NumberFormat.decimalPattern().format((double.tryParse(_amountController.text) ?? 0) * _commissionRate)} XOF'),
          const Divider(),
          _summaryRow('Montant net reçu', '${NumberFormat.decimalPattern().format(received > 0 ? received : 0)} XOF', isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 15 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinConfirmationSheet extends StatefulWidget {
  final Function(String) onSuccess;
  const _PinConfirmationSheet({required this.onSuccess});

  @override
  State<_PinConfirmationSheet> createState() => _PinConfirmationSheetState();
}

class _PinConfirmationSheetState extends State<_PinConfirmationSheet> {
  String _pin = '';

  void _onDigit(String digit) {
    if (_pin.length < 4) {
      setState(() => _pin += digit);
      if (_pin.length == 4) {
        widget.onSuccess(_pin);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Confirmation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Entrez votre code PIN pour valider le retrait'),
          const SizedBox(height: 32),
          PinDotsRow(enteredDigits: _pin.length),
          const SizedBox(height: 32),
          CustomKeyboard(
            onDigitTap: _onDigit,
            onBackspace: () => setState(() => _pin = _pin.isNotEmpty ? _pin.substring(0, _pin.length - 1) : ''),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
