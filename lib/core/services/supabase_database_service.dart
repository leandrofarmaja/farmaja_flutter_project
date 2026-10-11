import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/medicines/domain/medicine_model.dart';
import '../../features/pharmacies/domain/pharmacy_model.dart';
import '../../features/pharmacies/domain/pharmacy_payment_model.dart';
import '../../features/reservations/domain/reservation_model.dart';
import '../../features/prescriptions/domain/prescription_model.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/reviews/domain/review_model.dart';
import '../../features/admin/domain/admin_notification_model.dart';

class SupabaseDatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  // ============================================================
  // MEDICAMENTOS
  // Tabela real: medicamentos
  // ============================================================

  Future<List<MedicineModel>> getMedicines({
    String? query,
    String? province,
    bool? onlyInStock,
    bool? genericsOnly,
  }) async {
    if (province != null && province.trim().isNotEmpty) {
      throw UnsupportedError(
        'A tabela medicamentos ainda não possui uma coluna de província.',
      );
    }

    if (genericsOnly == true) {
      throw UnsupportedError(
        'A tabela medicamentos ainda não possui informação sobre genéricos.',
      );
    }

    try {
      final response = await _client
          .from('medicamentos')
          .select(
            'id, nome_medicamento, preco_kwanza, farmacia_id, '
            'disponivel, distancia_km, '
            'farmacias(id, nome, endereco, telefone, aberta_agora, avaliacao)',
          )
          .order('nome_medicamento');

      final rows = List<Map<String, dynamic>>.from(response);

      final filteredRows = rows.where((row) {
        final available = row['disponivel'] == true;

        if (onlyInStock == true && !available) {
          return false;
        }

        if (query != null && query.trim().isNotEmpty) {
          final name = (row['nome_medicamento'] ?? '')
              .toString()
              .toLowerCase();

          if (!name.contains(query.trim().toLowerCase())) {
            return false;
          }
        }

        return true;
      });

      return filteredRows.map(_medicineFromDatabase).toList();
    } catch (e) {
      throw Exception('Não foi possível carregar os medicamentos: $e');
    }
  }

  Future<MedicineModel?> getMedicineById(String id) async {
    try {
      final response = await _client
          .from('medicamentos')
          .select(
            'id, nome_medicamento, preco_kwanza, farmacia_id, '
            'disponivel, distancia_km, '
            'farmacias(id, nome, endereco, telefone, aberta_agora, avaliacao)',
          )
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return _medicineFromDatabase(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception('Não foi possível consultar o medicamento: $e');
    }
  }

  MedicineModel _medicineFromDatabase(Map<String, dynamic> row) {
    final pharmacyValue = row['farmacias'];

    Map<String, dynamic> pharmacy = {};

    if (pharmacyValue is Map) {
      pharmacy = Map<String, dynamic>.from(pharmacyValue);
    }

    final price = row['preco_kwanza'];
    final distance = row['distancia_km'];

    return MedicineModel(
      id: (row['id'] ?? '').toString(),
      pharmacyId: (row['farmacia_id'] ?? '').toString(),
      name: (row['nome_medicamento'] ?? '').toString(),
      activeIngredient: '',
      category: '',
      dosage: '',
      priceKz: price is num ? price.toDouble() : 0.0,
      pharmacyName: (pharmacy['nome'] ?? '').toString(),
      province: '',
      district: '',
      inStock: row['disponivel'] == true,
      stockQuantity: 0,
      requiresPrescription: false,
      isGeneric: false,
      genericAlternative: null,
      description: '',
      dosageInstructions: '',
      pharmacyLatitude: 0.0,
      pharmacyLongitude: 0.0,
    );
  }

  // ============================================================
  // FARMÁCIAS
  // Tabela real: farmacias
  // ============================================================

  Future<List<PharmacyModel>> getPharmacies({
    String? province,
    bool? only24h,
  }) async {
    if (province != null && province.trim().isNotEmpty) {
      throw UnsupportedError(
        'A tabela farmacias ainda não possui uma coluna de província.',
      );
    }

    if (only24h == true) {
      throw UnsupportedError(
        'A tabela farmacias ainda não possui informação sobre funcionamento 24 horas.',
      );
    }

    try {
      final response = await _client
          .from('farmacias')
          .select(
            'id, nome, avaliacao, endereco, telefone, '
            'aberta_agora, owner_user_id',
          )
          .order('nome');

      return List<Map<String, dynamic>>.from(response)
          .map(_pharmacyFromDatabase)
          .toList();
    } catch (e) {
      throw Exception('Não foi possível carregar as farmácias: $e');
    }
  }

  Future<List<PharmacyModel>> getAllPharmacies() {
    return getPharmacies();
  }

  Future<PharmacyModel?> getPharmacyById(String id) async {
    try {
      final response = await _client
          .from('farmacias')
          .select(
            'id, nome, avaliacao, endereco, telefone, '
            'aberta_agora, owner_user_id',
          )
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return _pharmacyFromDatabase(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception('Não foi possível consultar a farmácia: $e');
    }
  }

  PharmacyModel _pharmacyFromDatabase(Map<String, dynamic> row) {
    final rating = row['avaliacao'];

    return PharmacyModel(
      id: (row['id'] ?? '').toString(),
      name: (row['nome'] ?? '').toString(),
      province: '',
      district: '',
      address: (row['endereco'] ?? '').toString(),
      phone: (row['telefone'] ?? '').toString(),
      openingHours: row['aberta_agora'] == true
          ? 'Aberta'
          : 'Fechada',
      isOpen24h: false,
      hasDelivery: false,
      rating: rating is num ? rating.toDouble() : 0.0,
      logoUrl: '',
      latitude: 0.0,
      longitude: 0.0,
      subscriptionStatus: 'unknown',
      trialEndsAt: null,
      paymentDueDate: null,
      monthlyFee: 0.0,
      lastPaymentAt: null,
    );
  }

  // ============================================================
  // RESERVAS
  // Tabela real: reservas
  // ============================================================

  Future<List<ReservationModel>> getReservations(
    String userId,
  ) async {
    try {
      final response = await _client
          .from('reservas')
          .select(
            'id, medicamento_id, farmacia_id, status, '
            'codigo_reserva, url_foto_receita, criado_em, '
            'user_id, preco_kwanza, expira_em, receita_enviada, '
            'medicamentos(nome_medicamento), '
            'farmacias(nome)',
          )
          .eq('user_id', userId)
          .order('criado_em', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(_reservationFromDatabase)
          .toList();
    } catch (e) {
      throw Exception('Não foi possível carregar as reservas: $e');
    }
  }

  Future<ReservationModel> createReservation({
    required String userId,
    required String medicineName,
    required String pharmacyName,
    required double totalPriceKz,
    required bool prescriptionUploaded,
  }) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw Exception('É necessário iniciar sessão para reservar.');
    }

    if (currentUser.id != userId) {
      throw Exception(
        'O utilizador autenticado não corresponde ao utilizador da reserva.',
      );
    }

    try {
      final medicineResponse = await _client
          .from('medicamentos')
          .select('id, nome_medicamento, preco_kwanza, farmacia_id')
          .ilike('nome_medicamento', medicineName.trim())
          .limit(20);

      final medicines =
          List<Map<String, dynamic>>.from(medicineResponse);

      Map<String, dynamic>? selectedMedicine;

      for (final medicine in medicines) {
        final pharmacyId = medicine['farmacia_id'];

        if (pharmacyId == null) continue;

        final pharmacy = await _client
            .from('farmacias')
            .select('id, nome')
            .eq('id', pharmacyId)
            .maybeSingle();

        if (pharmacy != null &&
            pharmacy['nome'].toString().toLowerCase() ==
                pharmacyName.trim().toLowerCase()) {
          selectedMedicine = medicine;
          break;
        }
      }

      if (selectedMedicine == null) {
        throw Exception(
          'Não foi encontrado este medicamento na farmácia seleccionada.',
        );
      }

      final actualPrice = selectedMedicine['preco_kwanza'];

      if (actualPrice is! num ||
          actualPrice.toDouble() != totalPriceKz) {
        throw Exception(
          'O preço apresentado já não corresponde ao preço registado. '
          'Actualiza o catálogo e tenta novamente.',
        );
      }

      final reservationData = <String, dynamic>{
        'user_id': currentUser.id,
        'medicamento_id': selectedMedicine['id'],
        'farmacia_id': selectedMedicine['farmacia_id'],
        'status': 'Aguardando confirmação',
        'preco_kwanza': actualPrice,
        'receita_enviada': prescriptionUploaded,
      };

      final response = await _client
          .from('reservas')
          .insert(reservationData)
          .select(
            'id, medicamento_id, farmacia_id, status, '
            'codigo_reserva, url_foto_receita, criado_em, '
            'user_id, preco_kwanza, expira_em, receita_enviada, '
            'medicamentos(nome_medicamento), farmacias(nome)',
          )
          .single();

      return _reservationFromDatabase(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception('Não foi possível criar a reserva: $e');
    }
  }

  ReservationModel _reservationFromDatabase(
    Map<String, dynamic> row,
  ) {
    final medicineValue = row['medicamentos'];
    final pharmacyValue = row['farmacias'];

    final medicine = medicineValue is Map
        ? Map<String, dynamic>.from(medicineValue)
        : <String, dynamic>{};

    final pharmacy = pharmacyValue is Map
        ? Map<String, dynamic>.from(pharmacyValue)
        : <String, dynamic>{};

    final price = row['preco_kwanza'];

    return ReservationModel(
      id: (row['id'] ?? '').toString(),
      medicineName:
          (medicine['nome_medicamento'] ?? '').toString(),
      pharmacyId: (row['farmacia_id'] ?? '').toString(),
      pharmacyName: (pharmacy['nome'] ?? '').toString(),
      pickupCode: (row['codigo_reserva'] ?? '').toString(),
      totalPriceKz: price is num ? price.toDouble() : 0.0,
      reservationDate: (row['criado_em'] ?? '').toString(),
      expiryDate: (row['expira_em'] ?? '').toString(),
      status: (row['status'] ?? 'Aguardando confirmação').toString(),
      prescriptionUploaded: row['receita_enviada'] == true,
      isReviewed: false,
      reviewRating: null,
    );
  }

  // ============================================================
  // PERFIL DO UTILIZADOR
  // Tabela real: profiles
  // ============================================================

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select(
            'id, email, full_name, phone, province, district, '
            'insurance_provider, role, pharmacy_name',
          )
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return UserModel.fromJson(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception('Não foi possível carregar o perfil: $e');
    }
  }

  Future<void> upsertUserProfile(UserModel user) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null || currentUser.id != user.id) {
      throw Exception(
        'Só podes guardar o perfil do utilizador autenticado.',
      );
    }

    try {
      await _client.from('profiles').upsert(
        user.toJson(),
        onConflict: 'id',
      );
    } catch (e) {
      throw Exception(
        'Não foi possível guardar o perfil. '
        'Confirma as políticas RLS da tabela profiles: $e',
      );
    }
  }

  // ============================================================
  // OPERAÇÕES AINDA NÃO SUPORTADAS PELO ESQUEMA ACTUAL
  // Não simulam gravações nem devolvem sucesso fictício.
  // ============================================================

  Never _unsupported(String operation) {
    throw UnsupportedError(
      '$operation ainda não pode ser executado. '
      'A estrutura actual do Supabase não contém as tabelas '
      'ou colunas necessárias.',
    );
  }

  Future<void> updatePharmacySubscription({
    required String pharmacyId,
    required String status,
    DateTime? nextDueDate,
  }) async {
    _unsupported('Actualização da subscrição da farmácia');
  }

  Future<void> submitPharmacyPayment(
    PharmacyPaymentModel payment,
  ) async {
    _unsupported('Registo de pagamento da farmácia');
  }

  Future<List<PharmacyPaymentModel>> getAllPharmacyPayments() async {
    _unsupported('Consulta dos pagamentos das farmácias');
  }

  Future<void> approvePharmacyPayment({
    required String paymentId,
    required String pharmacyId,
    int periodMonths = 1,
  }) async {
    _unsupported('Aprovação de pagamento da farmácia');
  }

  Future<void> rejectPharmacyPayment(
    String paymentId,
    String? notes,
  ) async {
    _unsupported('Rejeição de pagamento da farmácia');
  }

  Future<void> addMedicine(MedicineModel medicine) async {
    _unsupported('Adição de medicamentos pelo painel da farmácia');
  }

  Future<void> updateMedicine(MedicineModel medicine) async {
    _unsupported('Actualização de medicamentos');
  }

  Future<void> updateMedicineStock(
    String medicineId,
    int newStock,
    bool inStock,
  ) async {
    _unsupported('Actualização do stock');
  }

  Future<void> updateMedicinePrice(
    String medicineId,
    double newPrice,
  ) async {
    _unsupported('Actualização do preço do medicamento');
  }

  Future<void> deleteMedicine(String medicineId) async {
    _unsupported('Eliminação de medicamentos');
  }

  Future<List<ReservationModel>> getAllReservationsForPharmacy({
    String? pharmacyName,
  }) async {
    _unsupported(
      'Consulta administrativa das reservas das farmácias',
    );
  }

  Future<ReservationModel?> validateReservationByQrCode(
    String code,
  ) async {
    _unsupported('Validação de reservas por código QR');
  }

  Future<void> updateReservationStatus(
    String reservationId,
    String newStatus,
  ) async {
    _unsupported(
      'Actualização do estado da reserva. '
      'A política RLS actual não permite esta operação.',
    );
  }

  Future<List<PrescriptionModel>> getPrescriptionsForPharmacy() async {
    _unsupported('Consulta de receitas médicas');
  }

  Future<void> updatePrescriptionStatus(
    String prescriptionId,
    String status,
    String? notes,
  ) async {
    _unsupported('Actualização do estado das receitas médicas');
  }

  Future<void> submitReview(ReviewModel review) async {
    _unsupported('Submissão de avaliações');
  }

  Future<List<ReviewModel>> getReviewsForPharmacy(
    String pharmacyId,
  ) async {
    _unsupported('Consulta de avaliações da farmácia');
  }

  Future<List<ReviewModel>> getAllReviews() async {
    _unsupported('Consulta de todas as avaliações');
  }

  Future<void> moderateReview({
    required String reviewId,
    required String status,
    String? note,
  }) async {
    _unsupported('Moderação de avaliações');
  }

  Future<void> _updatePharmacyAverageRating(
    String pharmacyId,
  ) async {
    _unsupported('Actualização da avaliação média da farmácia');
  }

  Future<List<AdminNotificationModel>> getAdminNotifications() async {
    _unsupported('Consulta de notificações administrativas');
  }

  Future<void> markAdminNotificationRead(
    String notificationId,
  ) async {
    _unsupported('Marcação de notificações como lidas');
  }
}

final supabaseDatabaseServiceProvider =
    Provider<SupabaseDatabaseService>((ref) {
  return SupabaseDatabaseService();
});
