class PharmacyPaymentModel {
  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final double amount;
  final String paymentMethod;
  final String? referenceNumber;
  final String? proofUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final int periodMonths;
  final String? notes;
  final DateTime createdAt;
  final DateTime? approvedAt;

  PharmacyPaymentModel({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    this.amount = 15000.0,
    required this.paymentMethod,
    this.referenceNumber,
    this.proofUrl,
    this.status = 'pending',
    this.periodMonths = 1,
    this.notes,
    required this.createdAt,
    this.approvedAt,
  });

  factory PharmacyPaymentModel.fromJson(Map<String, dynamic> json) {
    return PharmacyPaymentModel(
      id: json['id'] ?? '',
      pharmacyId: json['pharmacy_id'] ?? '',
      pharmacyName: json['pharmacy_name'] ?? '',
      amount: (json['amount'] ?? 15000.0).toDouble(),
      paymentMethod: json['payment_method'] ?? 'Transferência IBAN',
      referenceNumber: json['reference_number'],
      proofUrl: json['proof_url'],
      status: json['status'] ?? 'pending',
      periodMonths: json['period_months'] ?? 1,
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy_id': pharmacyId,
      'pharmacy_name': pharmacyName,
      'amount': amount,
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'proof_url': proofUrl,
      'status': status,
      'period_months': periodMonths,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
    };
  }
}
