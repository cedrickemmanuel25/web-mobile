class Transaction {
  final String id;
  final String reference;
  final String merchantName;
  final double amount;
  final double commission;
  final String status; // 'pending', 'processing', 'success', 'failed'
  final String walletType;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.reference,
    required this.merchantName,
    required this.amount,
    required this.commission,
    required this.status,
    required this.walletType,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      merchantName: json['merchant']?['name']?.toString() ?? json['merchant_name']?.toString() ?? 'Commerçant Inconnu',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      commission: double.tryParse(json['commission']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'pending',
      walletType: json['wallet_type']?.toString() ?? '-',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
