
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/reservation_model.dart';

class ReservationsNotifier extends StateNotifier<List<ReservationModel>> {
  ReservationsNotifier(
    this._dbService,
    this._userId,
  ) : super([]) {
    if (_userId != null && _userId!.isNotEmpty) {
      unawaited(fetchReservations());
      _configureRealtimeSubscription();
    }
  }

  final SupabaseDatabaseService _dbService;
  final String? _userId;

  RealtimeChannel? _reservationsChannel;

  bool _isFetching = false;
  bool _refreshRequested = false;

  Future<void> fetchReservations() async {
    final userId = _userId;

    if (userId == null || userId.isEmpty || !mounted) {
      if (mounted) state = [];
      return;
    }

    if (_isFetching) {
      _refreshRequested = true;
      return;
    }

    _isFetching = true;

    try {
      final reservations = await _dbService.getReservations(userId);

      if (!mounted) return;

      state = reservations;
    } catch (e) {
      if (mounted) {
        throw Exception(
          'Não foi possível carregar as reservas: $e',
        );
      }
    } finally {
      _isFetching = false;

      if (mounted && _refreshRequested) {
        _refreshRequested = false;
        unawaited(fetchReservations());
      }
    }
  }

  void _configureRealtimeSubscription() {
    final userId = _userId;

    if (userId == null || userId.isEmpty || !mounted) {
      return;
    }

    _reservationsChannel = _dbService.client
        .channel('farclik-client-reservations-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reservas',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (!mounted) return;

            // A alteração no Supabase é a fonte de verdade.
            // O provider volta a consultar a reserva completa.
            unawaited(fetchReservations());
          },
        )
        .subscribe();
  }

  Future<void> _removeRealtimeSubscription() async {
    final channel = _reservationsChannel;
    _reservationsChannel = null;

    if (channel != null) {
      await _dbService.client.removeChannel(channel);
    }
  }

  Future<ReservationModel> addReservation({
    required String medicineId,
    required String pharmacyId,
    required bool prescriptionUploaded,
    String? prescriptionPath,
  }) async {
    final userId = _userId;

    if (userId == null || userId.isEmpty) {
      throw Exception(
        'Inicia sessão para poderes efectuar uma reserva.',
      );
    }

    final newReservation = await _dbService.createReservation(
      userId: userId,
      medicineId: medicineId,
      pharmacyId: pharmacyId,
      prescriptionUploaded: prescriptionUploaded,
      prescriptionPath: prescriptionPath,
    );

    if (!mounted) return newReservation;

    state = [newReservation, ...state];

    return newReservation;
  }

  Future<ReservationModel> confirmarPagamentoComoCliente({
    required String reservationId,
  }) async {
    final userId = _userId;

    if (userId == null || userId.isEmpty) {
      throw Exception(
        'Inicia sessão para confirmares a compra.',
      );
    }

    final updatedReservation =
        await _dbService.clienteConfirmarPagamento(
      reservationId: reservationId,
    );

    if (!mounted) return updatedReservation;

    state = state.map((reservation) {
      return reservation.id == reservationId
          ? updatedReservation
          : reservation;
    }).toList();

    return updatedReservation;
  }

  void cancelReservation(String id) {
    throw UnsupportedError(
      'O cancelamento de reservas ainda não está implementado no Supabase.',
    );
  }

  void markReservationReviewed(
    String reservationId,
    double rating,
  ) {
    state = state.map((reservation) {
      if (reservation.id == reservationId) {
        return reservation.copyWith(
          isReviewed: true,
          reviewRating: rating,
        );
      }

      return reservation;
    }).toList();
  }

  @override
  void dispose() {
    unawaited(_removeRealtimeSubscription());
    super.dispose();
  }
}

final reservationsProvider =
    StateNotifierProvider<ReservationsNotifier, List<ReservationModel>>(
  (ref) {
    final dbService = ref.watch(supabaseDatabaseServiceProvider);
    final user = ref.watch(authProvider).user;

    return ReservationsNotifier(
      dbService,
      user?.id,
    );
  },
);
