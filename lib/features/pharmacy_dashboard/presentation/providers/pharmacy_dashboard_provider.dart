import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_database_service.dart';
import '../../../medicines/domain/medicine_model.dart';
import '../../../pharmacies/domain/pharmacy_model.dart';
import '../../../pharmacies/domain/pharmacy_payment_model.dart';
import '../../../reservations/domain/reservation_model.dart';
import '../../../prescriptions/domain/prescription_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
      activePharmacyName: activePharmacyName ?? this.activePharmacyName,
    );
  }

  // Subscription Status Helpers
  bool get isBlockedOrExpired => pharmacyDetails?.isBlockedOrExpired ?? false;
  bool get isTrialActive => pharmacyDetails?.isTrialActive ?? false;
  int get daysLeftInTrial => pharmacyDetails?.daysLeftInTrial ?? 0;
  int get daysUntilPaymentDue => pharmacyDetails?.daysUntilPaymentDue ?? 0;

  // Statistics calculations
  double get totalRevenue => reservations
      .where((r) => r.status == 'completed' || r.status == 'active')
      .fold(0.0, (sum, r) => sum + r.totalPriceKz);

  int get completedReservationsCount =>
      reservations.where((r) => r.status == 'completed').length;

  int get activeReservationsCount =>
      reservations.where((r) => r.status == 'active' || r.status == 'pending').length;

  int get pendingPrescriptionsCount =>
      prescriptions.where((p) => p.status == 'pending').length;

  int get totalStockItems =>
      medicines.fold(0, (sum, m) => sum + m.stockQuantity);
}

class PharmacyDashboardNotifier extends StateNotifier<PharmacyDashboardState> {
  final SupabaseDatabaseService _dbService;

  PharmacyDashboardNotifier(this._dbService)
      : super(PharmacyDashboardState(isLoading: true)) {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pharmacies = await _dbService.getPharmacies();
      PharmacyModel? currentPharm = pharmacies.firstWhere(
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
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Switch pharmacy profile for testing different subscription states (trial, active, expired, blocked)
  Future<void> switchPharmacy(PharmacyModel targetPharmacy) async {
    state = state.copyWith(
      activePharmacyName: targetPharmacy.name,
      pharmacyDetails: targetPharmacy,
    );
    await loadDashboardData();
  }

  /// Submit 15.000 Kz subscription payment proof
  Future<bool> submitPaymentProof({
    required String paymentMethod,
    required String referenceNumber,
    required String proofUrl,
    String? notes,
  }) async {
    final pharm = state.pharmacyDetails;
    if (pharm == null) return false;

    final newPayment = PharmacyPaymentModel(
      id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
      pharmacyId: pharm.id,
      pharmacyName: pharm.name,
      amount: 15000.0,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      proofUrl: proofUrl.isEmpty ? 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=500' : proofUrl,
      status: 'pending',
      periodMonths: 1,
      notes: notes,
      createdAt: DateTime.now(),
    );

    final success = await _dbService.submitPharmacyPayment(newPayment);
    if (success) {
      state = state.copyWith(payments: [newPayment, ...state.payments]);
    }
    return success;
  }

  /// Add new medicine to inventory
  Future<bool> addMedicine(MedicineModel newMedicine) async {
    final success = await _dbService.addMedicine(newMedicine);
    final updatedList = [newMedicine, ...state.medicines];
    state = state.copyWith(medicines: updatedList);
    return success;
  }

  /// Edit existing medicine
  Future<bool> updateMedicine(MedicineModel updatedMedicine) async {
    final success = await _dbService.updateMedicine(updatedMedicine);
    final updatedList = state.medicines.map((m) {
      return m.id == updatedMedicine.id ? updatedMedicine : m;
    }).toList();
    state = state.copyWith(medicines: updatedList);
    return success;
  }

  /// Update medicine stock in real time
  Future<bool> updateStock(String medicineId, int newStock) async {
    final inStock = newStock > 0;
    await _dbService.updateMedicineStock(medicineId, newStock, inStock);

    final updatedList = state.medicines.map((m) {
      if (m.id == medicineId) {
        return MedicineModel(
          id: m.id,
          pharmacyId: m.pharmacyId,
          name: m.name,
          activeIngredient: m.activeIngredient,
          category: m.category,
          dosage: m.dosage,
          priceKz: m.priceKz,
          pharmacyName: m.pharmacyName,
          province: m.province,
          district: m.district,
          inStock: inStock,
          stockQuantity: newStock,
          requiresPrescription: m.requiresPrescription,
          isGeneric: m.isGeneric,
          genericAlternative: m.genericAlternative,
          description: m.description,
          dosageInstructions: m.dosageInstructions,
          pharmacyLatitude: m.pharmacyLatitude,
          pharmacyLongitude: m.pharmacyLongitude,
        );
      }
      return m;
    }).toList();

    state = state.copyWith(medicines: updatedList);
    return true;
  }

  /// Update medicine price in real time
  Future<bool> updatePrice(String medicineId, double newPrice) async {
    await _dbService.updateMedicinePrice(medicineId, newPrice);

    final updatedList = state.medicines.map((m) {
      if (m.id == medicineId) {
        return MedicineModel(
          id: m.id,
          pharmacyId: m.pharmacyId,
          name: m.name,
          activeIngredient: m.activeIngredient,
          category: m.category,
          dosage: m.dosage,
          priceKz: newPrice,
          pharmacyName: m.pharmacyName,
          province: m.province,
          district: m.district,
          inStock: m.inStock,
          stockQuantity: m.stockQuantity,
          requiresPrescription: m.requiresPrescription,
          isGeneric: m.isGeneric,
          genericAlternative: m.genericAlternative,
          description: m.description,
          dosageInstructions: m.dosageInstructions,
          pharmacyLatitude: m.pharmacyLatitude,
          pharmacyLongitude: m.pharmacyLongitude,
        );
      }
      return m;
    }).toList();

    state = state.copyWith(medicines: updatedList);
    return true;
  }

  /// Delete medicine from inventory
  Future<bool> deleteMedicine(String medicineId) async {
    await _dbService.deleteMedicine(medicineId);
    final updatedList = state.medicines.where((m) => m.id != medicineId).toList();
    state = state.copyWith(medicines: updatedList);
    return true;
  }

  /// Validate reservation by QR code / Pickup code
  Future<ReservationModel?> validateQrCode(String code) async {
    final res = await _dbService.validateReservationByQrCode(code);
    if (res != null) {
      final updatedResList = state.reservations.map((r) {
        if (r.pickupCode.toUpperCase() == code.toUpperCase()) {
          return ReservationModel(
            id: r.id,
            medicineName: r.medicineName,
            pharmacyName: r.pharmacyName,
            pickupCode: r.pickupCode,
            totalPriceKz: r.totalPriceKz,
            reservationDate: r.reservationDate,
            expiryDate: r.expiryDate,
            status: 'completed',
            prescriptionUploaded: r.prescriptionUploaded,
          );
        }
        return r;
      }).toList();

      state = state.copyWith(reservations: updatedResList);
      return res;
    }
    return null;
  }

  /// Update prescription status (verified/rejected)
  Future<bool> updatePrescription(String id, String status, String? notes) async {
    await _dbService.updatePrescriptionStatus(id, status, notes);

    final updatedPrescriptionList = state.prescriptions.map((p) {
      if (p.id == id) {
        return PrescriptionModel(
          id: p.id,
          userId: p.userId,
          userName: p.userName,
          medicineName: p.medicineName,
          imageUrl: p.imageUrl,
          status: status,
          notes: notes ?? p.notes,
          createdAt: p.createdAt,
        );
      }
      return p;
    }).toList();

    state = state.copyWith(prescriptions: updatedPrescriptionList);
    return true;
  }
}

final pharmacyDashboardProvider =
    StateNotifierProvider<PharmacyDashboardNotifier, PharmacyDashboardState>((ref) {
  final dbService = ref.watch(supabaseDatabaseServiceProvider);
  return PharmacyDashboardNotifier(dbService);
});
