import 'dart:math';

class MedicineModel {
  final String id;
  final String pharmacyId;
  final String name;
  final String activeIngredient;
  final String category;
  final String dosage;
  final double priceKz;
  final String pharmacyName;
  final String province;
  final String district;
  final bool inStock;
  final int stockQuantity;
  final bool requiresPrescription;
  final bool isGeneric;
  final String? genericAlternative;
  final String description;
  final String dosageInstructions;
  final double pharmacyLatitude;
  final double pharmacyLongitude;

  MedicineModel({
    required this.id,
    this.pharmacyId = '',
    required this.name,
    required this.activeIngredient,
    required this.category,
    required this.dosage,
    required this.priceKz,
    required this.pharmacyName,
    required this.province,
    required this.district,
    required this.inStock,
    required this.stockQuantity,
    required this.requiresPrescription,
    required this.isGeneric,
    this.genericAlternative,
    required this.description,
    required this.dosageInstructions,
    this.pharmacyLatitude = -8.8383,
    this.pharmacyLongitude = 13.2344,
  });

  double calculateDistanceFrom(double userLat, double userLng) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((pharmacyLatitude - userLat) * p) / 2 +
        cos(userLat * p) * cos(pharmacyLatitude * p) *
            (1 - cos((pharmacyLongitude - userLng) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id'] ?? '',
      pharmacyId: json['pharmacy_id'] ?? json['pharmacyId'] ?? '',
      name: json['name'] ?? '',
      activeIngredient: json['generic_name'] ?? json['active_ingredient'] ?? json['activeIngredient'] ?? '',
      category: json['category'] ?? 'Geral',
      dosage: json['dosage'] ?? 'Caixa de Comprimidos',
      priceKz: (json['price'] ?? json['price_kz'] ?? json['priceKz'] ?? 0).toDouble(),
      pharmacyName: json['pharmacy_name'] ?? json['pharmacyName'] ?? 'Farmácia Local',
      province: json['province'] ?? 'Luanda',
      district: json['municipality'] ?? json['district'] ?? 'Talatona',
      inStock: json['in_stock'] ?? json['inStock'] ?? ((json['stock'] ?? 1) > 0),
      stockQuantity: json['stock'] ?? json['stock_quantity'] ?? json['stockQuantity'] ?? 10,
      requiresPrescription: json['prescription_required'] ?? json['requires_prescription'] ?? json['requiresPrescription'] ?? false,
      isGeneric: json['is_generic'] ?? json['isGeneric'] ?? false,
      genericAlternative: json['generic_alternative'] ?? json['genericAlternative'],
      description: json['description'] ?? '',
      dosageInstructions: json['dosage_instructions'] ?? json['dosageInstructions'] ?? 'Seguir a recomendação do médico.',
      pharmacyLatitude: (json['pharmacy_latitude'] ?? json['latitude'] ?? -8.8383).toDouble(),
      pharmacyLongitude: (json['pharmacy_longitude'] ?? json['longitude'] ?? 13.2344).toDouble(),
    );
  }
}
