
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
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (
        json['full_name'] ??
        json['fullName'] ??
        ''
      ).toString(),
      phone: (json['phone'] ?? '').toString(),
      province: (json['province'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      insuranceProvider:
          json['insurance_provider']?.toString(),
      role: (json['role'] ?? 'customer').toString(),
      pharmacyName:
          (json['pharmacy_name'] ?? json['pharmacyName'])
              ?.toString(),
    );
  }

  /// Representação completa para leitura e uso interno.
  /// Não utilizar este mapa directamente para actualizar
  /// o perfil do utilizador na base de dados.
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

  /// Apenas os campos que o utilizador pode actualizar
  /// segundo as permissões actuais da tabela profiles.
  Map<String, dynamic> toEditableProfileJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'province': province,
      'district': district,
      'insurance_provider': insuranceProvider,
    };
  }
}
