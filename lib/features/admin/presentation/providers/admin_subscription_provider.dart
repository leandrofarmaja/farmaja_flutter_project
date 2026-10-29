
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
    bool clearError = false,
  }) {
    return AdminSubscriptionState(
      pharmacies: pharmacies ?? this.pharmacies,
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  int get totalPharmacies => pharmacies.length;

  int get activeCount =>
      pharmacies.where((p) => p.subscriptionStatus == 'active').length;

  int get trialCount =>
      pharmacies.where((p) => p.subscriptionStatus == 'trial').length;

  int get expiredCount =>
      pharmacies.where((p) => p.subscriptionStatus == 'expired').length;

  int get blockedCount =>
      pharmacies.where((p) => p.subscriptionStatus == 'blocked').length;

  int get pendingPaymentsCount =>
      payments.where((p) => p.status == 'pending').length;
}

class AdminSubscriptionNotifier
    extends StateNotifier<AdminSubscriptionState> {
  final SupabaseDatabaseService _dbService;

  AdminSubscriptionNotifier(this._dbService)
      : super(AdminSubscriptionState(isLoading: true)) {
    loadAdminData();
  }

  Future<void> loadAdminData() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    String? pharmacyError;
    String? paymentError;

    // Carrega as farmácias independentemente dos pagamentos.
    try {
      final pharmList = await _dbService.getPharmacies();

      state = state.copyWith(
        pharmacies: pharmList,
        clearError: true,
      );
    } catch (e) {
      pharmacyError =
          'Não foi possível carregar as farmácias: $e';
    }

    // Uma falha nos pagamentos não deve apagar a lista de farmácias.
    try {
      final payList = await _dbService.getAllPharmacyPayments();

      state = state.copyWith(
        payments: payList,
      );
    } catch (e) {
      paymentError =
          'Os pagamentos não estão disponíveis neste momento: $e';
    }

    String? finalError;

    if (pharmacyError != null && paymentError != null) {
      finalError = '$pharmacyError\n$paymentError';
    } else {
      finalError = pharmacyError ?? paymentError;
    }

    state = state.copyWith(
      isLoading: false,
      error: finalError,
      clearError: finalError == null,
    );
  }

  /// Aprovação de pagamentos.
  /// Devolve false enquanto a operação não estiver implementada no serviço.
  Future<bool> approvePayment(
    String paymentId,
    String pharmacyId,
    int months,
  ) async {
    try {
      await _dbService.approvePharmacyPayment(
        paymentId: paymentId,
        pharmacyId: pharmacyId,
        periodMonths: months,
      );

      await loadAdminData();
      return true;
    } on UnsupportedError catch (e) {
      state = state.copyWith(
        error:
            'A aprovação de pagamentos ainda não está disponível: $e',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Não foi possível aprovar o pagamento: $e',
      );
      return false;
    }
  }

  /// Rejeição de pagamentos.
  Future<bool> rejectPayment(
    String paymentId,
    String? reason,
  ) async {
    try {
      await _dbService.rejectPharmacyPayment(
        paymentId,
        reason,
      );

      await loadAdminData();
      return true;
    } on UnsupportedError catch (e) {
      state = state.copyWith(
        error:
            'A rejeição de pagamentos ainda não está disponível: $e',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Não foi possível rejeitar o pagamento: $e',
      );
      return false;
    }
  }

  /// Alteração do estado da subscrição.
  Future<bool> setPharmacyStatus(
    String pharmacyId,
    String status, {
    DateTime? customDueDate,
  }) async {
    try {
      await _dbService.updatePharmacySubscription(
        pharmacyId: pharmacyId,
        status: status,
        nextDueDate: customDueDate,
      );

      await loadAdminData();
      return true;
    } on UnsupportedError catch (e) {
      state = state.copyWith(
        error:
            'A alteração de subscrições ainda não está disponível: $e',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Não foi possível alterar a subscrição: $e',
      );
      return false;
    }
  }
}

final adminSubscriptionProvider = StateNotifierProvider<
    AdminSubscriptionNotifier, AdminSubscriptionState>((ref) {
  final dbService = ref.watch(supabaseDatabaseServiceProvider);

  return AdminSubscriptionNotifier(dbService);
});
