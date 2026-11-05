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
  final String? imageUrl;

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
    this.imageUrl,
  });

  double calculateDistanceFrom(double userLat, double userLng) {
    const p = 0.017453292519943295;

    final a = 0.5 -
        cos((pharmacyLatitude - userLat) * p) / 2 +
        cos(userLat * p) *
            cos(pharmacyLatitude * p) *
            (1 - cos((pharmacyLongitude - userLng) * p)) / 2;

    return 12742 * asin(sqrt(a));
  }

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id']?.toString() ?? '',
      pharmacyId:
          json['pharmacy_id']?.toString() ??
          json['pharmacyId']?.toString() ??
          '',
      name: json['name']?.toString() ?? '',
      activeIngredient:
          json['generic_name']?.toString() ??
          json['active_ingredient']?.toString() ??
          json['activeIngredient']?.toString() ??
          '',
      category: json['category']?.toString() ?? 'Geral',
      dosage: json['dosage']?.toString() ?? 'Caixa de Comprimidos',
      priceKz: _toDouble(
        json['price'] ?? json['price_kz'] ?? json['priceKz'],
      ),
      pharmacyName:
          json['pharmacy_name']?.toString() ??
          json['pharmacyName']?.toString() ??
          'Farmácia Local',
      province: json['province']?.toString() ?? 'Luanda',
      district:
          json['municipality']?.toString() ??
          json['district']?.toString() ??
          'Talatona',
      inStock: _toBool(
        json['in_stock'] ??
            json['inStock'] ??
            _toInt(json['stock'] ?? 1) > 0,
      ),
      stockQuantity: _toInt(
        json['stock'] ??
            json['stock_quantity'] ??
            json['stockQuantity'] ??
            10,
      ),
      requiresPrescription: _toBool(
        json['prescription_required'] ??
            json['requires_prescription'] ??
            json['requiresPrescription'] ??
            false,
      ),
      isGeneric: _toBool(
        json['is_generic'] ?? json['isGeneric'] ?? false,
      ),
      genericAlternative:
          json['generic_alternative']?.toString() ??
          json['genericAlternative']?.toString(),
      description: json['description']?.toString() ?? '',
      dosageInstructions:
          json['dosage_instructions']?.toString() ??
          json['dosageInstructions']?.toString() ??
          'Seguir a recomendação do médico.',
      pharmacyLatitude: _toDouble(
        json['pharmacy_latitude'] ?? json['latitude'],
        fallback: -8.8383,
      ),
      pharmacyLongitude: _toDouble(
        json['pharmacy_longitude'] ?? json['longitude'],
        fallback: 13.2344,
      ),
      imageUrl: _readImageUrl(json),
    );
  }

  static String? _readImageUrl(Map<String, dynamic> json) {
    final value =
        json['imagem_url'] ??
        json['image_url'] ??
        json['imageUrl'];

    if (value == null) return null;

    final url = value.toString().trim();

    return url.isEmpty ? null : url;
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? fallback;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return false;
  }
}
