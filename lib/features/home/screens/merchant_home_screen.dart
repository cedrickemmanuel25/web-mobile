import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/auth_service.dart';

class MerchantHomeScreen extends ConsumerStatefulWidget {
  const MerchantHomeScreen({super.key});

  @override
  ConsumerState<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends ConsumerState<MerchantHomeScreen> {
  Map<String, dynamic>? _dashboardData;
  String? _qrCodeUrl;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) _fetchData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);
    
    try {
      final dashboard = await authService.getMerchantDashboard();
      final qrUrl = await authService.getMerchantQrCode();
      
      if (mounted) {
        setState(() {
          _dashboardData = dashboard;
          _qrCodeUrl = qrUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadQrCode() async {
    if (_qrCodeUrl == null) return;
    try {
      final response = await http.get(Uri.parse(_qrCodeUrl!));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/mon_qr_code.svg');
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('QR Code sauvegardé : ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du téléchargement')),
        );
      }
    }
  }

  Future<void> _shareQrCode() async {
    if (_qrCodeUrl == null) return;
    try {
      final response = await http.get(Uri.parse(_qrCodeUrl!));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/qr_code_ivoirepay.svg';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        await Share.shareXFiles([XFile(filePath)], text: 'Voici mon QR Code de paiement IvoirePay !');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du partage')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1B4332))),
      );
    }

    final double balance = double.tryParse(_dashboardData?['balance']?.toString() ?? '0') ?? 0;
    final today = _dashboardData?['today'] ?? {'revenue': 0, 'count': 0};
    final thisMonth = _dashboardData?['this_month'] ?? {'revenue': 0, 'count': 0};
    
    final double todayRevenue = double.tryParse(today['revenue']?.toString() ?? '0') ?? 0;
    final double thisMonthRevenue = double.tryParse(thisMonth['revenue']?.toString() ?? '0') ?? 0;
    
    final businessName = ref.watch(authProvider).user?.name ?? 'Commerçant';
    NumberFormat formatter;
    try {
      formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'XOF', decimalDigits: 0);
    } catch (_) {
      formatter = NumberFormat.currency(symbol: 'F', decimalDigits: 0);
    }

    const primaryColor = Color(0xFF1B4332);
    const accentColor = Color(0xFF2D6A4F);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Solde disponible', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatter.format(balance).replaceAll('XOF', 'F'),
                            style: GoogleFonts.inter(
                              fontSize: 36, 
                              fontWeight: FontWeight.w800, 
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.business_center_outlined, color: Colors.white70, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                businessName,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => context.push('/profile'),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Quick Action Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            context,
                            Icons.account_balance_wallet_outlined,
                            'Retirer',
                            const Color(0xFFE67E22),
                            '/withdrawal',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            context,
                            Icons.history_rounded,
                            'Transactions',
                            const Color(0xFF3498DB),
                            '/merchant-transactions',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Stats Section
                    Text(
                      'Aperçu des revenus',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Aujourd\'hui',
                            formatter.format(todayRevenue).replaceAll('XOF', 'F'),
                            '${today['count']} encaissements',
                            Icons.show_chart_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Ce mois',
                            formatter.format(thisMonthRevenue).replaceAll('XOF', 'F'),
                            '${thisMonth['count']} encaissements',
                            Icons.assessment_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // QR Code Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Votre QR Code de Paiement',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3436)),
                          ),
                          const SizedBox(height: 20),
                          if (_qrCodeUrl != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade100, width: 2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: SvgPicture.network(
                                _qrCodeUrl!,
                                width: 220,
                                height: 220,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: _downloadQrCode,
                                    icon: const Icon(Icons.file_download_outlined, size: 20),
                                    label: const Text('Sauvegarder'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: primaryColor,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                Container(width: 1, height: 20, color: Colors.grey.shade200),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: _shareQrCode,
                                    icon: const Icon(Icons.share_outlined, size: 20),
                                    label: const Text('Partager'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: primaryColor,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text('QR Code non disponible', style: TextStyle(color: Colors.grey)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 10,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.format_list_bulleted_rounded), label: 'Ventes'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Retraits'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade400,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) context.push('/merchant-transactions');
          else if (index == 2) context.push('/withdrawal');
          else if (index == 3) context.push('/profile');
        },
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String label, Color color, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF2D3436)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String amount, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF1B4332)),
          const SizedBox(height: 12),
          Text(
            amount,
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: const Color(0xFF1B4332), letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(color: Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 12),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

