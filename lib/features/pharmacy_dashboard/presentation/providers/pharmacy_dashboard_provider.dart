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
    this.activePharmacyName = 'Farmácia Mecofarma Talatona',
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

  bool get isTrialActive => pharmacyDetails?.isTrialActive ?? false;

  int get daysLeftInTrial => pharmacyDetails?.daysLeftInTrial ?? 0;

  int get daysUntilPaymentDue =>
      pharmacyDetails?.daysUntilPaymentDue ?? 0;

  double get totalRevenue => reservations
      .where((r) => r.status == 'completed' || r.status == 'active')
      .fold(0.0, (sum, r) => sum + r.totalPriceKz);

  int get completedReservationsCount =>
      reservations.where((r) => r.status == 'completed').length;

  int get activeReservationsCount => reservations
      .where((r) => r.status == 'active' || r.status == 'pending')
      .length;

  int get pendingPrescriptionsCount =>
      prescriptions.where((p) => p.status == 'pending').length;

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
    state = state.copyWith(isLoading: true, error: null);

    try {
      final pharmacies = await _dbService.getPharmacies();

      if (pharmacies.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Não existem farmácias disponíveis para apresentar.',
        );
        return;
      }

      PharmacyModel currentPharm = pharmacies.firstWhere(
        (p) => p.name == state.activePharmacyName,
        orElse: () => pharmacies.first,
      );

      final meds = await _dbService.getMedicines(
        province: currentPharm.province,
      );

      final res = await _dbService.getAllReservationsForPharmacy(
        pharmacyName: currentPharm.name,
      );

      final presc = await _dbService.getPrescriptionsForPharmacy();
      final pays = await _dbService.getAllPharmacyPayments();

      state = state.copyWith(
        pharmacyDetails: currentPharm,
        activePharmacyName: currentPharm.name,
        medicines: meds,
        reservations: res,
        prescriptions: presc,
        payments: pays,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar o painel da farmácia: $e',
      );
    }
  }

  Future<void> switchPharmacy(PharmacyModel targetPharmacy) async {
    state = state.copyWith(
      activePharmacyName: targetPharmacy.name,
      pharmacyDetails: targetPharmacy,
    );

    await loadDashboardData();
  }

  /// Envia comprovativo de pagamento.
  /// A operação permanece indisponível enquanto o serviço não a suportar.
  Future<bool> submitPaymentProof({
    required String paymentMethod,
    required String referenceNumber,
    required String proofUrl,
    String? notes,
  }) async {
    final pharm = state.pharmacyDetails;

    if (pharm == null) {
      state = state.copyWith(
        error: 'Não foi possível identificar a farmácia.',
      );
      return false;
    }

    final newPayment = PharmacyPaymentModel(
      id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
      pharmacyId: pharm.id,
      pharmacyName: pharm.name,
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

  /// Adiciona medicamento quando o serviço estiver implementado.
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

  /// Actualiza medicamento quando o serviço estiver implementado.
  Future<bool> updateMedicine(MedicineModel updatedMedicine) async {
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

  /// Actualiza stock quando o serviço estiver implementado.
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

  /// Actualiza preço quando o serviço estiver implementado.
  Future<bool> updatePrice(String medicineId, double newPrice) async {
    if (newPrice < 0) {
      state = state.copyWith(
        error: 'O preço não pode ser negativo.',
      );
      return false;
    }

    try {
      await _dbService.updateMedicinePrice(medicineId, newPrice);
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

  /// Elimina medicamento quando o serviço estiver implementado.
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

  /// Valida código de levantamento quando o serviço estiver implementado.
  Future<ReservationModel?> validateQrCode(String code) async {
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

  /// Actualiza o estado da receita quando o serviço estiver implementado.
  Future<bool> updatePrescription(
    String id,
    String status,
    String? notes,
  ) async {
    try {
      await _dbService.updatePrescriptionStatus(id, status, notes);
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
  final dbService = ref.watch(supabaseDatabaseServiceProvider);

  return PharmacyDashboardNotifier(dbService);
});
