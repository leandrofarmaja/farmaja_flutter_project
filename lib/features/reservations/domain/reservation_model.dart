class ReservationModel {
  final String id;
  final String medicineName;
  final String pharmacyId;
  final String pharmacyName;
  final String pickupCode;
  final double totalPriceKz;
  final String reservationDate;
  final String expiryDate;
  final String status; // 'active', 'completed', 'expired'
  final bool prescriptionUploaded;
  final bool isReviewed;
  final double? reviewRating;

  ReservationModel({
    required this.id,
    required this.medicineName,
    this.pharmacyId = 'pharm-1',
    required this.pharmacyName,
    required this.pickupCode,
    required this.totalPriceKz,
    required this.reservationDate,
    required this.expiryDate,
    required this.status,
    required this.prescriptionUploaded,
    this.isReviewed = false,
    this.reviewRating,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] ?? '',
      medicineName: json['medicine_name'] ?? json['medicineName'] ?? 'Medicamento FarmaJá',
      pharmacyId: json['pharmacy_id'] ?? json['pharmacyId'] ?? 'pharm-1',
      pharmacyName: json['pharmacy_name'] ?? json['pharmacyName'] ?? 'Farmácia',
      pickupCode: json['reservation_code'] ?? json['pickup_code'] ?? json['pickupCode'] ?? 'FJ-8921',
      totalPriceKz: (json['total_price_kz'] ?? json['totalPriceKz'] ?? json['price'] ?? 0).toDouble(),
      reservationDate: json['created_at'] ?? json['reservation_date'] ?? json['reservationDate'] ?? '22 Julho 2026',
      expiryDate: json['expires_at'] ?? json['expiry_date'] ?? json['expiryDate'] ?? '23 Julho 2026 - 18:00',
      status: json['status'] ?? 'pending',
      prescriptionUploaded: json['prescription_uploaded'] ?? json['prescriptionUploaded'] ?? false,
      isReviewed: json['is_reviewed'] ?? json['isReviewed'] ?? false,
      reviewRating: json['review_rating'] != null ? (json['review_rating'] as num).toDouble() : null,
    );
  }

  ReservationModel copyWith({
    String? status,
    bool? isReviewed,
    double? reviewRating,
  }) {
    return ReservationModel(
      id: id,
      medicineName: medicineName,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      pickupCode: pickupCode,
      totalPriceKz: totalPriceKz,
      reservationDate: reservationDate,
      expiryDate: expiryDate,
      status: status ?? this.status,
      prescriptionUploaded: prescriptionUploaded,
      isReviewed: isReviewed ?? this.isReviewed,
      reviewRating: reviewRating ?? this.reviewRating,
    );
  }
}
