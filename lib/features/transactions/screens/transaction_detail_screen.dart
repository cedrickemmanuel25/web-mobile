import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/transaction_service.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  Transaction? _transaction;
  bool _isLoading = true;
  String? _error;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final service = ref.read(transactionServiceProvider);
      final tx = await service.getTransactionDetails(widget.transactionId);
      if (mounted) {
        setState(() {
          _transaction = tx;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les détails de la transaction.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadReceipt() async {
    if (_transaction == null) return;
    
    setState(() => _isDownloading = true);
    try {
      final service = ref.read(transactionServiceProvider);
      final file = await service.downloadReceipt(_transaction!.id, _transaction!.reference);
      
      if (file != null && await file.exists()) {
        await OpenFilex.open(file.path);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors du téléchargement du reçu')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@ivoirepay.com',
      query: 'subject=Problème Transaction ${_transaction?.reference ?? ''}',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir l\'application email.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Détails', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: green))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 24),
                      Text('Timeline de paiement', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      _buildTimeline(),
                      const SizedBox(height: 32),
                      _buildActions(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    if (_transaction == null) return const SizedBox();
    final tx = _transaction!;
    final dateFormatted = DateFormat('dd MMMM yyyy, HH:mm').format(tx.createdAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            tx.status == 'success' ? Icons.check_circle : (tx.status == 'failed' ? Icons.cancel : Icons.pending),
            color: tx.status == 'success' ? Colors.green : (tx.status == 'failed' ? Colors.red : Colors.orange),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            '-${(tx.amount + tx.commission).toStringAsFixed(0)} XOF',
            style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1B4332)),
          ),
          const SizedBox(height: 4),
          Text(tx.merchantName, style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade700)),
          const Divider(height: 32),
          _detailRow('Statut', tx.status.toUpperCase(), isStatus: true),
          const SizedBox(height: 12),
          _detailRow('Date', dateFormatted),
          const SizedBox(height: 12),
          _detailRow('Référence', tx.reference),
          const SizedBox(height: 12),
          _detailRow('Wallet', tx.walletType),
          const SizedBox(height: 12),
          _detailRow('Montant net', '${tx.amount.toStringAsFixed(0)} XOF'),
          const SizedBox(height: 12),
          _detailRow('Commission', '${tx.commission.toStringAsFixed(0)} XOF'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontWeight: isStatus ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
              color: isStatus 
                ? (value == 'SUCCESS' ? Colors.green : (value == 'FAILED' ? Colors.red : Colors.orange))
                : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    if (_transaction == null) return const SizedBox();
    final status = _transaction!.status.toLowerCase();
    
    final isPending = true; // Always active initially
    final isProcessing = status != 'pending';
    final isDone = status == 'success' || status == 'failed';
    final isFailed = status == 'failed';

    return Column(
      children: [
        _timelineStep('Initiation', 'Le paiement a été créé', true, isLast: false),
        _timelineStep('Traitement', 'En cours de validation opérateur', isProcessing, isLast: false),
        _timelineStep(
          isFailed ? 'Échec' : 'Terminé',
          isFailed ? 'La transaction a échoué' : 'Paiement effectué avec succès',
          isDone,
          isLast: true,
          isError: isFailed,
        ),
      ],
    );
  }

  Widget _timelineStep(String title, String subtitle, bool isActive, {bool isLast = false, bool isError = false}) {
    final color = isActive ? (isError ? Colors.red : const Color(0xFF1B4332)) : Colors.grey.shade300;
    
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: isActive ? Colors.white : Colors.transparent, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: color),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isActive ? Colors.black87 : Colors.grey)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _isDownloading ? null : _downloadReceipt,
            icon: _isDownloading 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.download),
            label: Text(_isDownloading ? 'Téléchargement...' : 'Télécharger le reçu PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1B4332),
              side: const BorderSide(color: Color(0xFF1B4332)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: TextButton.icon(
            onPressed: _contactSupport,
            icon: const Icon(Icons.report_problem_outlined, color: Colors.red),
            label: const Text('Signaler un problème', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }
}
