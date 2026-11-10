
class ReservationModel {
  final String id;
  final String medicineName;
  final String? medicineImageUrl;
  final String pharmacyId;
  final String pharmacyName;
  final String pickupCode;
  final double totalPriceKz;
  final String reservationDate;
  final String expiryDate;
  final String status;
  final bool prescriptionUploaded;
  final bool isReviewed;
  final double? reviewRating;

  // Confirmação bilateral do pagamento.
  final String? metodoPagamento;
  final DateTime? clienteConfirmouPagamentoEm;
  final DateTime? farmaciaConfirmouPagamentoEm;

  // Validação presencial do código QR.
  final DateTime? qrValidadoEm;

  // Verificação presencial da receita médica.
  final bool? receitaAutorizada;
  final DateTime? receitaVerificadaEm;

  ReservationModel({
    required this.id,
    required this.medicineName,
    this.medicineImageUrl,
    this.pharmacyId = '',
    required this.pharmacyName,
    required this.pickupCode,
    required this.totalPriceKz,
    required this.reservationDate,
    required this.expiryDate,
    required this.status,
    required this.prescriptionUploaded,
    this.isReviewed = false,
    this.reviewRating,
    this.metodoPagamento,
    this.clienteConfirmouPagamentoEm,
    this.farmaciaConfirmouPagamentoEm,
    this.qrValidadoEm,
    this.receitaAutorizada,
    this.receitaVerificadaEm,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: _stringValue(json['id']),
      medicineName: _stringValue(
        json['medicine_name'] ?? json['medicineName'],
        fallback: 'Medicamento',
      ),
      medicineImageUrl: _nullableString(
        json['imagem_url'] ??
            json['medicine_image_url'] ??
            json['medicineImageUrl'],
      ),
      pharmacyId: _stringValue(
        json['pharmacy_id'] ?? json['pharmacyId'],
      ),
      pharmacyName: _stringValue(
        json['pharmacy_name'] ?? json['pharmacyName'],
        fallback: 'Farmácia',
      ),
      pickupCode: _stringValue(
        json['reservation_code'] ??
            json['pickup_code'] ??
            json['pickupCode'],
      ),
      totalPriceKz: _doubleValue(
        json['total_price_kz'] ??
            json['totalPriceKz'] ??
            json['price'],
      ),
      reservationDate: _stringValue(
        json['created_at'] ??
            json['reservation_date'] ??
            json['reservationDate'],
      ),
      expiryDate: _stringValue(
        json['expires_at'] ??
            json['expiry_date'] ??
            json['expiryDate'],
      ),
      status: _stringValue(
        json['status'],
        fallback: 'Aguardando confirmação',
      ),
      prescriptionUploaded: _boolValue(
        json['prescription_uploaded'] ??
            json['prescriptionUploaded'],
      ),
      isReviewed: _boolValue(
        json['is_reviewed'] ?? json['isReviewed'],
      ),
      reviewRating: _nullableDouble(
        json['review_rating'] ?? json['reviewRating'],
      ),
      metodoPagamento: _nullableString(
        json['metodo_pagamento'] ?? json['metodoPagamento'],
      ),
      clienteConfirmouPagamentoEm: _dateTimeValue(
        json['cliente_confirmou_pagamento_em'] ??
            json['clienteConfirmouPagamentoEm'],
      ),
      farmaciaConfirmouPagamentoEm: _dateTimeValue(
        json['farmacia_confirmou_pagamento_em'] ??
            json['farmaciaConfirmouPagamentoEm'],
      ),
      qrValidadoEm: _dateTimeValue(
        json['qr_validado_em'] ?? json['qrValidadoEm'],
      ),
      receitaAutorizada: _nullableBool(
        json['receita_autorizada'] ?? json['receitaAutorizada'],
      ),
      receitaVerificadaEm: _dateTimeValue(
        json['receita_verificada_em'] ??
            json['receitaVerificadaEm'],
      ),
    );
  }

  ReservationModel copyWith({
    String? status,
    bool? isReviewed,
    double? reviewRating,
    String? medicineImageUrl,
    String? metodoPagamento,
    DateTime? clienteConfirmouPagamentoEm,
    DateTime? farmaciaConfirmouPagamentoEm,
    DateTime? qrValidadoEm,
    bool? receitaAutorizada,
    DateTime? receitaVerificadaEm,
    bool limparImagemMedicamento = false,
    bool limparMetodoPagamento = false,
    bool limparConfirmacaoCliente = false,
    bool limparConfirmacaoFarmacia = false,
    bool limparValidacaoQr = false,
    bool limparAutorizacaoReceita = false,
    bool limparVerificacaoReceita = false,
    bool limparReviewRating = false,
  }) {
    return ReservationModel(
      id: id,
      medicineName: medicineName,
      medicineImageUrl: limparImagemMedicamento
          ? null
          : medicineImageUrl ?? this.medicineImageUrl,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      pickupCode: pickupCode,
      totalPriceKz: totalPriceKz,
      reservationDate: reservationDate,
      expiryDate: expiryDate,
      status: status ?? this.status,
      prescriptionUploaded: prescriptionUploaded,
      isReviewed: isReviewed ?? this.isReviewed,
      reviewRating: limparReviewRating
          ? null
          : reviewRating ?? this.reviewRating,
      metodoPagamento: limparMetodoPagamento
          ? null
          : metodoPagamento ?? this.metodoPagamento,
      clienteConfirmouPagamentoEm: limparConfirmacaoCliente
          ? null
          : clienteConfirmouPagamentoEm ??
              this.clienteConfirmouPagamentoEm,
      farmaciaConfirmouPagamentoEm: limparConfirmacaoFarmacia
          ? null
          : farmaciaConfirmouPagamentoEm ??
              this.farmaciaConfirmouPagamentoEm,
      qrValidadoEm: limparValidacaoQr
          ? null
          : qrValidadoEm ?? this.qrValidadoEm,
      receitaAutorizada: limparAutorizacaoReceita
          ? null
          : receitaAutorizada ?? this.receitaAutorizada,
      receitaVerificadaEm: limparVerificacaoReceita
          ? null
          : receitaVerificadaEm ?? this.receitaVerificadaEm,
    );
  }

  static String _stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;
    return value.toString();
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;

    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  static double _doubleValue(dynamic value) {
    return _nullableDouble(value) ?? 0.0;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString());
  }

  static bool _boolValue(dynamic value) {
    return _nullableBool(value) ?? false;
  }

  static bool? _nullableBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;

    if (value is num) {
      return value != 0;
    }

    final normalized = value.toString().toLowerCase().trim();

    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;

    return null;
  }

  static DateTime? _dateTimeValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    return DateTime.tryParse(value.toString());
  }
}
