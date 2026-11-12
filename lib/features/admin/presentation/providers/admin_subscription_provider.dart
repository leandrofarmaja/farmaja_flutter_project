
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_database_service.dart';
import '../../../pharmacies/domain/pharmacy_model.dart';
import '../../../pharmacies/domain/pharmacy_payment_model.dart';

class AdminSubscriptionState {
  final List<PharmacyModel> pharmacies;
  final List<PharmacyPaymentModel> payments;
  final Map<String, dynamic> indicators;
  final bool isLoading;
  final String? error;

  AdminSubscriptionState({
    this.pharmacies = const [],
    this.payments = const [],
    this.indicators = const {},
    this.isLoading = false,
    this.error,
  });

  AdminSubscriptionState copyWith({
    List<PharmacyModel>? pharmacies,
    List<PharmacyPaymentModel>? payments,
    Map<String, dynamic>? indicators,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminSubscriptionState(
      pharmacies: pharmacies ?? this.pharmacies,
      payments: payments ?? this.payments,
      indicators: indicators ?? this.indicators,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  int get totalPharmacies => _indicatorInt(
        'total_farmacias',
        fallback: pharmacies.length,
      );

  int get totalCustomers => _indicatorInt('total_clientes');

  int get totalReservations => _indicatorInt('total_reservas');

  int get customersWithConfirmedPayment =>
      _indicatorInt('clientes_com_pagamento_confirmado');

  int get confirmedPaymentsCount =>
      _indicatorInt('reservas_com_pagamento_confirmado');

  double get confirmedPaymentsValue =>
      _indicatorDouble('valor_pagamentos_confirmados_kwanza');

  int get activeCount => _indicatorInt(
        'farmacias_activas',
        fallback: pharmacies
            .where((p) => p.subscriptionStatus == 'active')
            .length,
      );

  int get trialCount => _indicatorInt(
        'farmacias_trial',
        fallback: pharmacies
            .where((p) => p.subscriptionStatus == 'trial')
            .length,
      );

  int get expiredCount => _indicatorInt(
        'farmacias_expiradas',
        fallback: pharmacies
            .where((p) => p.subscriptionStatus == 'expired')
            .length,
      );

  int get blockedCount => _indicatorInt(
        'farmacias_bloqueadas',
        fallback: pharmacies
            .where((p) => p.subscriptionStatus == 'blocked')
            .length,
      );

  int get pendingPaymentsCount =>
      payments.where((p) => p.status == 'pending').length;

  int _indicatorInt(String key, {int fallback = 0}) {
    final value = indicators[key];

    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _indicatorDouble(String key) {
    final value = indicators[key];

    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}

class AdminSubscriptionNotifier
    extends StateNotifier<AdminSubscriptionState> {
  final SupabaseDatabaseService _dbService;

  AdminSubscriptionNotifier(this._dbService)
      : super(AdminSubscriptionState(isLoading: true)) {
    loadAdminData();
  }

  /// Carrega os dados administrativos.
  ///
  /// Cada fonte é carregada independentemente.
  /// Uma falha não impede a tentativa de carregar as restantes.
  Future<void> loadAdminData() async {
    await _reloadAdminData();
  }

  /// Devolve true apenas quando todas as fontes foram actualizadas.
  ///
  /// Se uma operação anterior já tiver sido gravada, uma falha
  /// nesta recarga não invalida o sucesso dessa operação.
  Future<bool> _reloadAdminData({
    String? completedOperation,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    String? pharmacyError;
    String? paymentError;
    String? indicatorError;

    // 1. Carregar farmácias.
    try {
      final pharmList = await _dbService.getPharmacies();

      state = state.copyWith(
        pharmacies: pharmList,
      );
    } catch (e) {
      pharmacyError =
          'Não foi possível carregar as farmácias: $e';
    }

    // 2. Carregar pagamentos de subscrições.
    try {
      final payList = await _dbService.getAllPharmacyPayments();

      state = state.copyWith(
        payments: payList,
      );
    } on UnsupportedError catch (e) {
      paymentError =
          'Os pagamentos de subscrições ainda não estão implementados: $e';
    } catch (e) {
      paymentError =
          'Os pagamentos de subscrições não estão disponíveis: $e';
    }

    // 3. Carregar indicadores administrativos.
    try {
      final result = await _dbService.client.rpc(
        'farclik_obter_indicadores_admin',
      );

      if (result is Map) {
        state = state.copyWith(
          indicators: Map<String, dynamic>.from(result),
        );
      } else {
        throw Exception(
          'O Supabase devolveu um formato inesperado para os indicadores.',
        );
      }
    } catch (e) {
      indicatorError =
          'Não foi possível carregar os indicadores: $e';
    }

    final errors = <String>[
      if (pharmacyError != null) pharmacyError,
      if (paymentError != null) paymentError,
      if (indicatorError != null) indicatorError,
    ];

    String? finalError;

    if (errors.isNotEmpty) {
      final details = errors.join('\n');

      if (completedOperation != null) {
        finalError =
            '$completedOperation foi concluída, mas alguns dados '
            'não puderam ser actualizados:\n$details';
      } else {
        finalError = details;
      }
    }

    state = state.copyWith(
      isLoading: false,
      error: finalError,
      clearError: finalError == null,
    );

    return errors.isEmpty;
  }

  /// Aprovação de pagamentos de subscrições.
  Future<bool> approvePayment(
    String paymentId,
    String pharmacyId,
    int months,
  ) async {
    state = state.copyWith(clearError: true);

    try {
      await _dbService.approvePharmacyPayment(
        paymentId: paymentId,
        pharmacyId: pharmacyId,
        periodMonths: months,
      );

      await _reloadAdminData(
        completedOperation: 'A aprovação do pagamento',
      );

      // A escrita foi concluída. Uma falha na recarga
      // não transforma a operação numa falha.
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

  /// Rejeição de pagamentos de subscrições.
  Future<bool> rejectPayment(
    String paymentId,
    String? reason,
  ) async {
    state = state.copyWith(clearError: true);

    try {
      await _dbService.rejectPharmacyPayment(
        paymentId,
        reason,
      );

      await _reloadAdminData(
        completedOperation: 'A rejeição do pagamento',
      );

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

  /// Alteração do estado da subscrição de uma farmácia.
  Future<bool> setPharmacyStatus(
    String pharmacyId,
    String status, {
    DateTime? customDueDate,
  }) async {
    state = state.copyWith(clearError: true);

    try {
      await _dbService.updatePharmacySubscription(
        pharmacyId: pharmacyId,
        status: status,
        nextDueDate: customDueDate,
      );

      await _reloadAdminData(
        completedOperation: 'A alteração da subscrição',
      );

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
