
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_database_service.dart';
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

  PharmacyDashboardState({
    this.medicines = const [],
    this.reservations = const [],
    this.prescriptions = const [],
    this.payments = const [],
    this.pharmacyDetails,
    this.isLoading = false,
    this.error,
    this.activePharmacyName,
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
        status == 'aguardando confirmacao';
  }

  double get totalRevenue => reservations
      .where((r) => _isCompleted(r))
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

  PharmacyDashboardNotifier(this._dbService)
      : super(PharmacyDashboardState(isLoading: true)) {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      // 1. Carregar o catálogo de farmácias.
      final pharmacies = await _dbService.getPharmacies();

      if (pharmacies.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Não existem farmácias disponíveis para apresentar.',
        );
        return;
      }

      // Mantém a selecção visual existente, se ainda existir.
      // A autorização das reservas continua a ser feita no Supabase.
      final currentPharmacy = pharmacies.cast<PharmacyModel?>().firstWhere(
            (p) => p?.name == state.activePharmacyName,
            orElse: () => pharmacies.first,
          )!;

      // 2. Carregar os dados essenciais separadamente.
      // Uma falha opcional não deve impedir as reservas.
      List<MedicineModel> medicines = [];
      List<ReservationModel> reservations = [];
      List<PrescriptionModel> prescriptions = [];
      List<PharmacyPaymentModel> payments = [];

      String? loadingError;

      try {
        medicines = await _dbService.getMedicines();
      } catch (e) {
        loadingError = 'Não foi possível carregar os medicamentos: $e';
      }

      try {
        // A função SQL filtra as reservas pela farmácia
        // associada ao utilizador autenticado.
        // Não aplicar um filtro pelo nome escolhido na interface.
        reservations =
            await _dbService.getAllReservationsForPharmacy();
      } catch (e) {
        loadingError =
            '${loadingError == null ? '' : '$loadingError\n'}'
            'Não foi possível carregar as reservas: $e';
      }

      // 3. Receitas: funcionalidade ainda não implementada.
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

      // 4. Pagamentos: funcionalidade ainda não implementada.
      try {
        payments = await _dbService.getAllPharmacyPayments();
      } on UnsupportedError {
        payments = [];
      } catch (e) {
        loadingError =
            '${loadingError == null ? '' : '$loadingError\n'}'
            'Não foi possível carregar os pagamentos: $e';
      }

      // 5. Guardar os dados, mesmo que uma área opcional falhe.
      state = state.copyWith(
        pharmacyDetails: currentPharmacy,
        activePharmacyName: currentPharmacy.name,
        medicines: medicines,
        reservations: reservations,
        prescriptions: prescriptions,
        payments: payments,
        isLoading: false,
        error: loadingError,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar o painel da farmácia: $e',
      );
    }
  }

  Future<void> switchPharmacy(
    PharmacyModel targetPharmacy,
  ) async {
    state = state.copyWith(
      activePharmacyName: targetPharmacy.name,
      pharmacyDetails: targetPharmacy,
    );

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

    final newPayment = PharmacyPaymentModel(
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
      await _dbService.submitPharmacyPayment(newPayment);
      await loadDashboardData();
      return true;
    } on UnsupportedError {
      state = state.copyWith(
        error:
            'O envio de comprovativos ainda não está implementado no serviço.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Não foi possível enviar o comprovativo: $e',
      );
      return false;
    }
  }

  Future<bool> addMedicine(MedicineModel newMedicine) async {
    try {
      await _dbService.addMedicine(newMedicine);
      await loadDashboardData();
      return true;
    } on UnsupportedError {
      state = state.copyWith(
        error:
            'A criação de medicamentos ainda não está implementada no serviço.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Não foi possível adicionar o medicamento: $e',
      );
      return false;
    }
  }

  Future<bool> updateMedicine(
    MedicineModel updatedMedicine,
  ) async {
    try {
      await _dbService.updateMedicine(updatedMedicine);
      await loadDashboardData();
      return true;
    } on UnsupportedError {
      state = state.copyWith(
        error:
            'A edição de medicamentos ainda não está implementada no serviço.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Não foi possível actualizar o medicamento: $e',
      );
      return false;
    }
  }

  Future<bool> updateStock(
    String medicineId,
    int newStock,
  ) async {
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
      state = state.copyWith(
        error:
            'A actualização do stock ainda não está implementada no serviço.',
      );
      return false;
    } catch (e) {
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
    if (newPrice < 0) {
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
      state = state.copyWith(
        error:
            'A alteração de preços ainda não está implementada no serviço.',
      );
      return false;
    } catch (e) {
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
      state = state.copyWith(
        error:
            'A eliminação de medicamentos ainda não está implementada no serviço.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Não foi possível eliminar o medicamento: $e',
      );
      return false;
    }
  }

  Future<ReservationModel?> validateQrCode(
    String code,
  ) async {
    try {
      final reservation =
          await _dbService.validateReservationByQrCode(code);

      if (reservation != null) {
        await loadDashboardData();
      }

      return reservation;
    } on UnsupportedError {
      state = state.copyWith(
        error:
            'A validação de códigos ainda não está implementada no serviço.',
      );
      return null;
    } catch (e) {
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
      state = state.copyWith(
        error:
            'A actualização de receitas ainda não está implementada no serviço.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Não foi possível actualizar a receita: $e',
      );
      return false;
    }
  }
}

final pharmacyDashboardProvider = StateNotifierProvider<
    PharmacyDashboardNotifier, PharmacyDashboardState>((ref) {
  final dbService = ref.watch(
    supabaseDatabaseServiceProvider,
  );

  return PharmacyDashboardNotifier(dbService);
});
