import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'payment_success_screen.dart';

const double _commissionRate = 0.0; // Commission retirée selon la demande client (anciennement 1.5%)

class PaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> qrData;

  const PaymentScreen({super.key, required this.qrData});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _amountController = TextEditingController();
  final _walletNumberController = TextEditingController();
  String _selectedWallet = 'wave';
  bool _isLoading = false;
  String? _amountError;

  static const _wallets = [
    {'id': 'wave', 'label': 'Wave', 'color': Color(0xFF2196F3), 'logo': 'assets/images/wave.jpg'},
    {'id': 'orange', 'label': 'Orange', 'color': Color(0xFFFF6D00), 'logo': 'assets/images/orange.jpg'},
    {'id': 'mtn', 'label': 'MTN', 'color': Color(0xFFFDD835), 'logo': 'assets/images/mtn.jpg'},
    {'id': 'djamo', 'label': 'Djamo', 'color': Color(0xFF673AB7), 'logo': 'assets/images/djamo.jpg'},
    {'id': 'moov', 'label': 'Moov', 'color': Color(0xFFFF9800), 'logo': 'assets/images/moov.png'},
  ];

  double get _amount => double.tryParse(_amountController.text) ?? 0;
  double get _commission => _amount * _commissionRate;
  double get _total => _amount + _commission;

  String get _merchantName => widget.qrData['merchant_name'] ?? 'Commerçant';
  String get _merchantId => widget.qrData['merchant_id']?.toString() ?? '';

  void _validateAmount(String val) {
    final v = double.tryParse(val) ?? 0;
    setState(() {
      if (v < 100) _amountError = 'Montant minimum : 100 XOF';
      else if (v > 500000) _amountError = 'Montant maximum : 500 000 XOF';
      else _amountError = null;
    });
  }

  Future<void> _initPayment() async {
    if (_amountError != null || _amount < 100) {
      _validateAmount(_amountController.text);
      return;
    }
    if (_walletNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre numéro de wallet')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.initiateTransaction(
        merchantId: _merchantId,
        amount: _amount,
        walletType: _selectedWallet,
        walletNumber: _walletNumberController.text,
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final txData = response.data;
        _showConfirmationSheet(txData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Erreur lors de l\'initiation')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showConfirmationSheet(Map<String, dynamic> txData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentConfirmationSheet(
        txData: txData,
        merchantName: _merchantName,
        amount: _amount,
        commission: _commission,
        walletType: _selectedWallet,
        walletNumber: _walletNumberController.text,
        onSuccess: () {
          context.go('/payment-success', extra: {
            'reference': txData['reference'] ?? (txData['transaction_id'] ?? txData['id'])?.toString() ?? 'N/A',
            'merchant': _merchantName,
            'amount': _amount,
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: Text('Paiement QR', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Merchant card
            _buildMerchantCard(),
            const SizedBox(height: 24),

            // Amount input
            _buildSectionTitle('Montant'),
            const SizedBox(height: 8),
            _buildAmountField(),
            const SizedBox(height: 24),

            // Wallet selector
            _buildSectionTitle('Moyen de paiement'),
            const SizedBox(height: 12),
            _buildWalletSelector(),
            const SizedBox(height: 16),

            // Wallet number
            _buildSectionTitle('Numéro de wallet'),
            const SizedBox(height: 8),
            _buildWalletNumberField(),
            const SizedBox(height: 24),

            // Recap
            if (_amount >= 100) ...[
              _buildRecap(),
              const SizedBox(height: 24),
            ],

            // Pay button
            _buildPayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B4332).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _merchantName.isNotEmpty ? _merchantName[0].toUpperCase() : 'M',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _merchantName,
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  'ID: $_merchantId',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified, color: Color(0xFF1B4332)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: _validateAmount,
      decoration: InputDecoration(
        hintText: 'ex: 5000',
        suffixText: 'XOF',
        errorText: _amountError,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B4332), width: 2),
        ),
      ),
    );
  }

  Widget _buildWalletSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _wallets.map((w) {
        final selected = _selectedWallet == w['id'];
        final color = w['color'] as Color;
        final size = (MediaQuery.of(context).size.width - 60) / 3; // 3 items per row approx
        
        return GestureDetector(
          onTap: () => setState(() => _selectedWallet = w['id'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? color.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? color : Colors.grey.shade200,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected ? [
                BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
              ] : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      color: selected ? color : Colors.grey,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  w['label'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? color : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWalletNumberField() {
    return TextField(
      controller: _walletNumberController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: 'ex: 0700000000',
        prefixIcon: const Icon(Icons.phone_android),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B4332), width: 2),
        ),
      ),
    );
  }

  Widget _buildRecap() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _recapRow('Montant', '${_amount.toStringAsFixed(0)} XOF'),
          if (_commission > 0) ...[
            const Divider(height: 16),
            _recapRow('Commission (1.5%)', '${_commission.toStringAsFixed(0)} XOF', subtle: true),
          ],
          const Divider(height: 16),
          _recapRow('Total à payer', '${_total.toStringAsFixed(0)} XOF', bold: true),
        ],
      ),
    );
  }

  Widget _recapRow(String label, String value, {bool bold = false, bool subtle = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(
          fontSize: 14, 
          color: subtle ? Colors.grey : Colors.black87,
        )),
        Text(value, style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: bold ? const Color(0xFF1B4332) : Colors.black87,
        )),
      ],
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _initPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B4332),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Payer ${_amount >= 100 ? "${_total.toStringAsFixed(0)} XOF" : ""}',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

// ─── Confirmation Bottom Sheet ────────────────────────────────────────────────
class PaymentConfirmationSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> txData;
  final String merchantName;
  final double amount;
  final double commission;
  final String walletType;
  final String walletNumber;
  final VoidCallback onSuccess;

  const PaymentConfirmationSheet({
    super.key,
    required this.txData,
    required this.merchantName,
    required this.amount,
    required this.commission,
    required this.walletType,
    required this.walletNumber,
    required this.onSuccess,
  });

  @override
  ConsumerState<PaymentConfirmationSheet> createState() => _PaymentConfirmationSheetState();
}

class _PaymentConfirmationSheetState extends ConsumerState<PaymentConfirmationSheet> {
  String _pin = '';
  bool _isLoading = false;
  String? _error;
  final _pinDigits = List.generate(15, (i) => i.toString()).toList()
    ..shuffle();

  List<String> get _shuffledKeys {
    final keys = ['0','1','2','3','4','5','6','7','8','9'];
    keys.shuffle();
    return keys;
  }

  late final List<String> _keys = _shuffledKeys;

  Future<void> _confirm() async {
    if (_pin.length < 4) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      // Backend returns transaction_id, not id
      final txId = widget.txData['transaction_id']?.toString() ?? widget.txData['id']?.toString() ?? '';
      
      final response = await authService.confirmTransaction(txId, _pin, widget.walletNumber);
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        widget.onSuccess();
      } else {
        setState(() {
          _error = response.data['message'] ?? 'Erreur lors de la confirmation';
          _pin = '';
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.response?.data['message'] ?? 'Erreur réseau (${e.type.name}).';
          _pin = '';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Erreur inattendue. Réessayez.'; _pin = ''; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          )),
          const SizedBox(height: 20),
          Text('Confirmer le paiement', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Recap
          _recapCard(),
          const SizedBox(height: 24),

          Text('Entrez votre PIN pour valider', style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 12),

          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 14, height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pin.length ? const Color(0xFF1B4332) : Colors.grey.shade300,
              ),
            )),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],

          const SizedBox(height: 16),

          // Random keyboard
          _buildKeyboard(),

          const SizedBox(height: 16),

          if (_isLoading) const CircularProgressIndicator(color: Color(0xFF1B4332))
          else if (_pin.length == 4)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Confirmer', style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,
                )),
              ),
            ),
        ],
      ),
    );
  }

  Widget _recapCard() {
    final total = widget.amount + widget.commission;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Commerçant', style: GoogleFonts.inter(color: Colors.grey)),
            Text(widget.merchantName, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Montant', style: GoogleFonts.inter(color: Colors.grey)),
            Text('${widget.amount.toStringAsFixed(0)} XOF', style: GoogleFonts.inter()),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Commission', style: GoogleFonts.inter(color: Colors.grey)),
            Text('${widget.commission.toStringAsFixed(0)} XOF', style: GoogleFonts.inter()),
          ]),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            Text('${total.toStringAsFixed(0)} XOF',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1B4332), fontSize: 16)),
          ]),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    return Column(
      children: [
        for (int row = 0; row < 3; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int col = 0; col < 3; col++)
                _keyButton(_keys[row * 3 + col]),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72),
            _keyButton(_keys[9]),
            _keyButton('⌫', isBackspace: true),
          ],
        ),
      ],
    );
  }

  Widget _keyButton(String key, {bool isBackspace = false}) {
    return GestureDetector(
      onTap: () {
        if (isBackspace) {
          if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
        } else if (_pin.length < 4) {
          setState(() => _pin += key);
          if (_pin.length == 4) _confirm();
        }
      },
      child: Container(
        width: 72,
        height: 64,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            key,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
