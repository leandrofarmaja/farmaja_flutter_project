
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/supabase_database_service.dart';
import '../../../../core/services/pharmacy_notification_service.dart';
import '../../../medicines/domain/medicine_model.dart';
import '../../../pharmacies/domain/pharmacy_model.dart';
import '../../../pharmacies/domain/pharmacy_payment_model.dart';
import '../../../reservations/domain/reservation_model.dart';
import '../../../prescriptions/domain/prescription_model.dart';

class PharmacyDashboardState {
  final List<MedicineModel> medicines;
  final List<ReservationModel> reservations;
  final List<PrescriptionModel> prescriptions;
  final List<PharmacyPaymentModel> payments;
  final PharmacyModel? pharmacyDetails;
  final bool isLoading;
  final String? error;
  final String? activePharmacyName;
  final int unreadReservationsCount;

  PharmacyDashboardState({
    this.medicines = const [],
    this.reservations = const [],
    this.prescriptions = const [],
    this.payments = const [],
    this.pharmacyDetails,
    this.isLoading = false,
    this.error,
    this.activePharmacyName,
    this.unreadReservationsCount = 0,
  });

  PharmacyDashboardState copyWith({
    List<MedicineModel>? medicines,
    List<ReservationModel>? reservations,
    List<PrescriptionModel>? prescriptions,
    List<PharmacyPaymentModel>? payments,
    PharmacyModel? pharmacyDetails,
    bool? isLoading,
    String? error,
    String? activePharmacyName,
    int? unreadReservationsCount,
  }) {
    return PharmacyDashboardState(
      medicines: medicines ?? this.medicines,
      reservations: reservations ?? this.reservations,
      prescriptions: prescriptions ?? this.prescriptions,
      payments: payments ?? this.payments,
      pharmacyDetails: pharmacyDetails ?? this.pharmacyDetails,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activePharmacyName:
          activePharmacyName ?? this.activePharmacyName,
      unreadReservationsCount:
          unreadReservationsCount ?? this.unreadReservationsCount,
    );
  }

  bool get isBlockedOrExpired =>
      pharmacyDetails?.isBlockedOrExpired ?? false;

  bool get isTrialActive =>
      pharmacyDetails?.isTrialActive ?? false;

  int get daysLeftInTrial =>
      pharmacyDetails?.daysLeftInTrial ?? 0;

  int get daysUntilPaymentDue =>
      pharmacyDetails?.daysUntilPaymentDue ?? 0;

  bool _isCompleted(ReservationModel reservation) {
    final status = reservation.status.trim().toLowerCase();

    return status == 'completed' ||
        status == 'levantada' ||
        status == 'resgatado' ||
        status == 'entregue';
  }

  bool _isActive(ReservationModel reservation) {
    final status = reservation.status.trim().toLowerCase();

    return status == 'active' ||
        status == 'pending' ||
        status == 'aguardando confirmação' ||
        status == 'aguardando confirmacao' ||
        status == 'pago';
  }

  double get totalRevenue => reservations
      .where(_isCompleted)
      .fold(0.0, (sum, r) => sum + r.totalPriceKz);

  int get completedReservationsCount =>
      reservations.where(_isCompleted).length;

  int get activeReservationsCount =>
      reservations.where(_isActive).length;

  int get pendingPrescriptionsCount => prescriptions
      .where((p) => p.status.toLowerCase() == 'pending')
      .length;

  int get totalStockItems =>
      medicines.fold(0, (sum, m) => sum + m.stockQuantity);
}

class PharmacyDashboardNotifier
    extends StateNotifier<PharmacyDashboardState> {
  final SupabaseDatabaseService _dbService;
  final PharmacyNotificationService _notificationService;

  static const Duration _saveTimeout = Duration(seconds: 25);

  RealtimeChannel? _notificationChannel;
  String? _subscribedPharmacyId;

  PharmacyDashboardNotifier(this._dbService)
      : _notificationService =
            PharmacyNotificationService(_dbService),
        super(PharmacyDashboardState(isLoading: true)) {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final pharmacy = await _dbService.getOwnedPharmacy();

      if (pharmacy == null) {
        if (!mounted) return;

        await _removeNotificationSubscription();

        state = PharmacyDashboardState(
          isLoading: false,
          error:
              'Esta conta não tem uma farmácia associada. '
              'Confirma o registo e a associação da conta no Supabase.',
        );
        return;
      }

      List<MedicineModel> medicines = [];
      List<ReservationModel> reservations = [];
      List<PrescriptionModel> prescriptions = [];
      List<PharmacyPaymentModel> payments = [];
      String? loadingError;

      try {
        medicines = await _dbService.getMedicines(
          pharmacyId: pharmacy.id,
        );
      } catch (e) {
        loadingError =
            'Não foi possível carregar os medicamentos: $e';
      }

      try {
        reservations =
            await _dbService.getAllReservationsForPharmacy();
      } catch (e) {
        loadingError =
            '${loadingError == null ? '' : '$loadingError\n'}'
            'Não foi possível carregar as reservas: $e';
      }

      try {
        prescriptions =
            await _dbService.getPrescriptionsForPharmacy();
      } on UnsupportedError {
        prescriptions = [];
      } catch (e) {
        loadingError =
            '${loadingError == null ? '' : '$loadingError\n'}'
            'Não foi possível carregar as receitas: $e';
      }

      try {
        payments = await _dbService.getAllPharmacyPayments();
      } on UnsupportedError {
        payments = [];
      } catch (e) {
        loadingError =
            '${loadingError == null ? '' : '$loadingError\n'}'
            'Não foi possível carregar os pagamentos: $e';
      }

      if (!mounted) return;

      state = state.copyWith(
        pharmacyDetails: pharmacy,
        activePharmacyName: pharmacy.name,
        medicines: medicines,
        reservations: reservations,
        prescriptions: prescriptions,
        payments: payments,
        isLoading: false,
        error: loadingError,
      );

      await _configureNotificationSubscription(pharmacy.id);
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar o painel da farmácia: $e',
      );
    }
  }

  Future<void> _configureNotificationSubscription(
    String pharmacyId,
  ) async {
    if (!mounted) return;

    if (_subscribedPharmacyId == pharmacyId &&
        _notificationChannel != null) {
      await _refreshUnreadCount(pharmacyId);
      return;
    }

    await _removeNotificationSubscription();

    if (!mounted) return;

    try {
      final count =
          await _notificationService.getUnreadCount(pharmacyId);

      if (!mounted) return;

      if (state.pharmacyDetails?.id != pharmacyId) return;

      state = state.copyWith(
        unreadReservationsCount: count,
      );

      _notificationChannel =
          _notificationService.subscribeToNewNotifications(
        pharmacyId: pharmacyId,
        onInsert: (PostgresChangePayload payload) {
          if (!mounted) return;

          if (state.pharmacyDetails?.id != pharmacyId) return;

          unawaited(_refreshUnreadCount(pharmacyId));
        },
      );

      _subscribedPharmacyId = pharmacyId;
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        error:
            'Não foi possível activar as notificações '
            'de novas reservas: $e',
      );
    }
  }

  Future<void> _refreshUnreadCount(String pharmacyId) async {
    try {
      final count =
          await _notificationService.getUnreadCount(pharmacyId);

      if (!mounted) return;

      if (state.pharmacyDetails?.id != pharmacyId) return;

      state = state.copyWith(
        unreadReservationsCount: count,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        error:
            'Não foi possível actualizar o contador de reservas: $e',
      );
    }
  }

  Future<void> markReservationNotificationsAsRead() async {
    final pharmacy = state.pharmacyDetails;

    if (pharmacy == null) return;

    try {
      await _notificationService.markAsRead(pharmacy.id);

      if (!mounted) return;

      await _refreshUnreadCount(pharmacy.id);
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        error:
            'Não foi possível marcar as notificações como lidas: $e',
      );
    }
  }

  Future<void> _removeNotificationSubscription() async {
    final channel = _notificationChannel;

    _notificationChannel = null;
    _subscribedPharmacyId = null;

    if (channel != null) {
      await _dbService.client.removeChannel(channel);
    }
  }

  @override
  void dispose() {
    unawaited(_removeNotificationSubscription());
    super.dispose();
  }

  Future<void> _refreshMedicinesAfterMutation() async {
    try {
      final pharmacy = await _dbService
          .getOwnedPharmacy()
          .timeout(_saveTimeout);

      if (!mounted || pharmacy == null) return;

      final medicines = await _dbService
          .getMedicines(pharmacyId: pharmacy.id)
          .timeout(_saveTimeout);

      if (!mounted) return;

      state = state.copyWith(
        pharmacyDetails: pharmacy,
        activePharmacyName: pharmacy.name,
        medicines: medicines,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        error:
            'A operação foi concluída, mas não foi possível '
            'actualizar a lista de medicamentos. Detalhe: $e',
      );
    }
  }

  Future<void> switchPharmacy(PharmacyModel targetPharmacy) async {
    final pharmacy = await _dbService.getOwnedPharmacy();

    if (pharmacy == null || pharmacy.id != targetPharmacy.id) {
      if (!mounted) return;

      state = state.copyWith(
        error:
            'Não podes abrir o painel de uma farmácia '
            'que não esteja associada à tua conta.',
      );
      return;
    }

    await loadDashboardData();
  }

  Future<ReservationModel> confirmarPagamentoComoFarmacia({
    required String reservationId,
  }) async {
    final pharmacy = state.pharmacyDetails;

    if (pharmacy == null) {
      throw Exception(
        'Não foi possível identificar a farmácia da conta.',
      );
    }

    final reservation = state.reservations.where(
      (item) => item.id == reservationId,
    );

    if (reservation.isEmpty ||
        reservation.first.pharmacyId != pharmacy.id) {
      throw Exception(
        'Esta reserva não pertence à farmácia associada à conta.',
      );
    }

    final updatedReservation =
        await _dbService.farmaciaConfirmarPagamento(
      reservationId: reservationId,
    );

    if (!mounted) return updatedReservation;

    state = state.copyWith(
      reservations: state.reservations.map((item) {
        return item.id == reservationId
            ? updatedReservation
            : item;
      }).toList(),
      error: null,
    );

    return updatedReservation;
  }

  /// Confirma a entrega física do medicamento ao cliente.
  ///
  /// Só permite avançar quando:
  /// - A reserva pertence à farmácia autenticada.
  /// - O pagamento foi confirmado pelas duas partes.
  /// - O estado actual da reserva é Pago.
  Future<void> confirmarLevantamento(
    String reservationId,
  ) async {
    final pharmacy = state.pharmacyDetails;

    if (pharmacy == null) {
      throw Exception(
        'Não foi possível identificar a farmácia da conta.',
      );
    }

    final matchingReservations = state.reservations.where(
      (item) => item.id == reservationId,
    );

    if (matchingReservations.isEmpty) {
      throw Exception(
        'A reserva não foi encontrada no painel desta farmácia.',
      );
    }

    final reservation = matchingReservations.first;

    if (reservation.pharmacyId != pharmacy.id) {
      throw Exception(
        'Esta reserva não pertence à farmácia associada à conta.',
      );
    }

    if (reservation.status.trim().toLowerCase() != 'pago') {
      throw Exception(
        'O levantamento só pode ser confirmado depois '
        'da confirmação do pagamento.',
      );
    }

    if (reservation.clienteConfirmouPagamentoEm == null ||
        reservation.farmaciaConfirmouPagamentoEm == null) {
      throw Exception(
        'O pagamento ainda não foi confirmado pelas duas partes.',
      );
    }

    await _dbService.confirmarLevantamento(reservationId);

    if (!mounted) return;

    await loadDashboardData();
  }

  Future<bool> submitPaymentProof({
    required String paymentMethod,
    required String referenceNumber,
    required String proofUrl,
    String? notes,
  }) async {
    final pharmacy = state.pharmacyDetails;

    if (pharmacy == null) {
      state = state.copyWith(
        error: 'Não foi possível identificar a farmácia.',
      );
      return false;
    }

    final payment = PharmacyPaymentModel(
      id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
      pharmacyId: pharmacy.id,
      pharmacyName: pharmacy.name,
      amount: 15000.0,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      proofUrl: proofUrl,
      status: 'pending',
      periodMonths: 1,
      notes: notes,
      createdAt: DateTime.now(),
    );

    try {
      await _dbService.submitPharmacyPayment(payment);
      await loadDashboardData();
      return true;
    } on UnsupportedError {
      if (!mounted) return false;

      state = state.copyWith(
        error:
            'O envio de comprovativos ainda não está implementado no serviço.',
      );
      return false;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(
        error: 'Não foi possível enviar o comprovativo: $e',
      );
      return false;
    }
  }

  Future<bool> addMedicine(
    MedicineModel medicine, {
    XFile? image,
  }) async {
    final pharmacy = state.pharmacyDetails;

    if (pharmacy == null || pharmacy.id.trim().isEmpty) {
      state = state.copyWith(
        error:
            'Não foi possível identificar a farmácia da conta. '
            'Actualiza o painel e tenta novamente.',
      );
      return false;
    }

    if (medicine.name.trim().isEmpty) {
      state = state.copyWith(
        error: 'O nome do medicamento é obrigatório.',
      );
      return false;
    }

    if (!medicine.priceKz.isFinite ||
        medicine.priceKz < 0 ||
        medicine.stockQuantity < 0) {
      state = state.copyWith(
        error:
            'O preço e o stock devem ser valores válidos e não negativos.',
      );
      return false;
    }

    final medicineForPharmacy = MedicineModel(
      id: medicine.id,
      pharmacyId: pharmacy.id,
      name: medicine.name.trim(),
      activeIngredient: medicine.activeIngredient,
      category: medicine.category,
      dosage: medicine.dosage,
      priceKz: medicine.priceKz,
      pharmacyName: pharmacy.name,
      province: medicine.province,
      district: medicine.district,
      inStock: medicine.inStock,
      stockQuantity: medicine.stockQuantity,
      requiresPrescription: medicine.requiresPrescription,
      isGeneric: medicine.isGeneric,
      genericAlternative: medicine.genericAlternative,
      description: medicine.description,
      dosageInstructions: medicine.dosageInstructions,
      pharmacyLatitude: medicine.pharmacyLatitude,
      pharmacyLongitude: medicine.pharmacyLongitude,
    );

    try {
      await _dbService
          .addMedicine(
            medicineForPharmacy,
            image: image,
          )
          .timeout(_saveTimeout);

      if (!mounted) return false;

      unawaited(_refreshMedicinesAfterMutation());
      return true;
    } on TimeoutException {
      if (!mounted) return false;

      state = state.copyWith(
        error:
            'A gravação excedeu 25 segundos. Verifica a ligação '
            'e o estado do Supabase antes de tentares novamente.',
      );
      return false;
    } on UnsupportedError {
      if (!mounted) return false;

      state = state.copyWith(
        error:
            'A criação de medicamentos ainda não está implementada no serviço.',
      );
      return false;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(
        error: 'Não foi possível adicionar o medicamento: $e',
      );
      return false;
    }
  }

  Future<bool> updateMedicine(
    MedicineModel medicine, {
    XFile? image,
  }) async {
    final pharmacy = state.pharmacyDetails;

    if (pharmacy == null) {
      state = state.copyWith(
        error: 'Não foi possível identificar a farmácia da conta.',
      );
      return false;
    }

    if (medicine.pharmacyId.isNotEmpty &&
        medicine.pharmacyId != pharmacy.id) {
      state = state.copyWith(
        error:
            'Só podes editar medicamentos da farmácia associada à conta.',
      );
      return false;
    }

    try {
      await _dbService
          .updateMedicine(
            medicine,
            image: image,
          )
          .timeout(_saveTimeout);

      if (!mounted) return false;

      unawaited(_refreshMedicinesAfterMutation());
      return true;
    } on TimeoutException {
      if (!mounted) return false;

      state = state.copyWith(
        error:
            'A actualização excedeu 25 segundos. Verifica a ligação '
            'e o estado do Supabase antes de tentares novamente.',
      );
      return false;
    } on UnsupportedError {
      if (!mounted) return false;

      state = state.copyWith(
        error:
            'A edição de medicamentos ainda não está implementada no serviço.',
      );
      return false;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(
        error: 'Não foi possível actualizar o medicamento: $e',
      );
      return false;
    }
  }

  Future<bool> updateStock(String medicineId, int newStock) async {
    if (newStock < 0) {
      state = state.copyWith(
        error: 'O stock não pode ser negativo.',
      );
      return false;
    }

    try {
      await _dbService.updateMedicineStock(
        medicineId,
        newStock,
        newStock > 0,
      );
      await loadDashboardData();
      return true;
    } on UnsupportedError {
      if (!mounted) return false;

      state = state.copyWith(
        error:
            'A actualização do stock ainda não está implementada no serviço.',
      );
      return false;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(
        error: 'Não foi possível actualizar o stock: $e',
      );
      return false;
    }
  }

  Future<bool> updatePrice(
    String medicineId,
    double newPrice,
  ) async {
    if (!newPrice.isFinite || newPrice < 0) {
      state = state.copyWith(
        error: 'O preço não pode ser negativo.',
      );
      return false;
    }

    try {
      await _dbService.updateMedicinePrice(
        medicineId,
        newPrice,
      );
      await loadDashboardData();
      return true;
    } on UnsupportedError {
      if (!mounted) return false;

      state = state.copyWith(
        error:
            'A alteração de preços ainda não está implementada no serviço.',
      );
      return false;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(
        error: 'Não foi possível actualizar o preço: $e',
      );
      return false;
    }
  }

  Future<bool> deleteMedicine(String medicineId) async {
    try {
      await _dbService.deleteMedicine(medicineId);
      await loadDashboardData();
      return true;
    } on UnsupportedError {
      if (!mounted) return false;

      state = state.copyWith(
        error:
            'A eliminação de medicamentos ainda não está implementada no serviço.',
      );
      return false;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(
        error: 'Não foi possível eliminar o medicamento: $e',
      );
      return false;
    }
  }

  Future<ReservationModel?> validateQrCode(String code) async {
    try {
      final normalizedCode = code.trim();

      if (normalizedCode.isEmpty) {
        throw Exception('Introduz um código de reserva válido.');
      }

      // A validação do QR Code é apenas de leitura.
      // Não confirma o pagamento nem o levantamento.
      // Não recarrega nem altera os dados do painel.
      return await _dbService.validateReservationByQrCode(
        normalizedCode,
      );
    } on UnsupportedError {
      if (!mounted) return null;

      state = state.copyWith(
        error:
            'A validação de códigos ainda não está implementada no serviço.',
      );
      return null;
    } catch (e) {
      if (!mounted) return null;

      state = state.copyWith(
        error: 'Não foi possível validar o código: $e',
      );
      return null;
    }
  }

  Future<bool> updatePrescription(
    String id,
    String status,
    String? notes,
  ) async {
    try {
      await _dbService.updatePrescriptionStatus(
        id,
        status,
        notes,
      );
      await loadDashboardData();
      return true;
    } on UnsupportedError {
      if (!mounted) return false;

      state = state.copyWith(
        error:
            'A actualização de receitas ainda não está implementada no serviço.',
      );
      return false;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(
        error: 'Não foi possível actualizar a receita: $e',
      );
      return false;
    }
  }
}

final pharmacyDashboardProvider = StateNotifierProvider<
    PharmacyDashboardNotifier, PharmacyDashboardState>((ref) {
  final dbService = ref.watch(supabaseDatabaseServiceProvider);
  return PharmacyDashboardNotifier(dbService);
});
