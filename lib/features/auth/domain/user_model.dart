class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String province;
  final String district;
  final String? insuranceProvider;
  final String role;
  final String? pharmacyName;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.province,
    required this.district,
    this.insuranceProvider,
    this.role = 'customer',
    this.pharmacyName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? 'Utilizador FarmaJá',
      phone: json['phone'] ?? '+244 923 000 000',
      province: json['province'] ?? 'Luanda',
      district: json['district'] ?? 'Talatona',
      insuranceProvider: json['insurance_provider'] ?? 'ENSA Seguros',
      role: json['role'] ?? 'customer',
      pharmacyName: json['pharmacy_name'] ?? json['pharmacyName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'province': province,
      'district': district,
      'insurance_provider': insuranceProvider,
      'role': role,
      'pharmacy_name': pharmacyName,
    };
  }
}
