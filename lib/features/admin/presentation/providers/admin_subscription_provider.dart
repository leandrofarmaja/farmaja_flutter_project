import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_database_service.dart';
import '../../../pharmacies/domain/pharmacy_model.dart';
import '../../../pharmacies/domain/pharmacy_payment_model.dart';

class AdminSubscriptionState {
  final List<PharmacyModel> pharmacies;
  final List<PharmacyPaymentModel> payments;
  final bool isLoading;
  final String? error;

  AdminSubscriptionState({
    this.pharmacies = const [],
    this.payments = const [],
    this.isLoading = false,
    this.error,
  });

  AdminSubscriptionState copyWith({
    List<PharmacyModel>? pharmacies,
    List<PharmacyPaymentModel>? payments,
    bool? isLoading,
    String? error,
  }) {
    return AdminSubscriptionState(
      pharmacies: pharmacies ?? this.pharmacies,
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get totalPharmacies => pharmacies.length;
  int get activeCount => pharmacies.where((p) => p.subscriptionStatus == 'active').length;
  int get trialCount => pharmacies.where((p) => p.subscriptionStatus == 'trial').length;
  int get expiredCount => pharmacies.where((p) => p.subscriptionStatus == 'expired').length;
  int get blockedCount => pharmacies.where((p) => p.subscriptionStatus == 'blocked').length;
  int get pendingPaymentsCount => payments.where((p) => p.status == 'pending').length;
}

class AdminSubscriptionNotifier extends StateNotifier<AdminSubscriptionState> {
  final SupabaseDatabaseService _dbService;

  AdminSubscriptionNotifier(this._dbService)
      : super(AdminSubscriptionState(isLoading: true)) {
    loadAdminData();
  }

  Future<void> loadAdminData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pharmList = await _dbService.getPharmacies();
      final payList = await _dbService.getAllPharmacyPayments();

      state = state.copyWith(
        pharmacies: pharmList,
        payments: payList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Approve payment proof & extend subscription for a pharmacy
  Future<bool> approvePayment(String paymentId, String pharmacyId, int months) async {
    final success = await _dbService.approvePharmacyPayment(
      paymentId: paymentId,
      pharmacyId: pharmacyId,
      periodMonths: months,
    );
    await loadAdminData();
    return success;
  }

  /// Reject payment with notes
  Future<bool> rejectPayment(String paymentId, String? reason) async {
    final success = await _dbService.rejectPharmacyPayment(paymentId, reason);
    await loadAdminData();
    return success;
  }

  /// Change subscription status directly (trial, active, expired, blocked)
  Future<bool> setPharmacyStatus(String pharmacyId, String status, {DateTime? customDueDate}) async {
    final success = await _dbService.updatePharmacySubscription(
      pharmacyId: pharmacyId,
      status: status,
      nextDueDate: customDueDate,
    );
    await loadAdminData();
    return success;
  }
}

final adminSubscriptionProvider =
    StateNotifierProvider<AdminSubscriptionNotifier, AdminSubscriptionState>((ref) {
  final dbService = ref.watch(supabaseDatabaseServiceProvider);
  return AdminSubscriptionNotifier(dbService);
});
