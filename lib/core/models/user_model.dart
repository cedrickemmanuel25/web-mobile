class User {
  final int id;
  final String name;
  final String phone;
  final String role;
  final String? avatar;
  final String? kycStatus; // 'unsubmitted', 'pending', 'approved', 'rejected'
  final bool hasPin;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.avatar,
    this.kycStatus,
    this.hasPin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      role: json['role'],
      avatar: json['avatar'],
      kycStatus: json['kyc_status'],
      hasPin: json['has_pin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'avatar': avatar,
      'kyc_status': kycStatus,
      'has_pin': hasPin,
    };
  }
}
