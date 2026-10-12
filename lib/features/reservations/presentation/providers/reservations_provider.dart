import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/reservation_model.dart';

class ReservationsNotifier
    extends StateNotifier<List<ReservationModel>> {
  ReservationsNotifier(
    this._dbService,
    this._userId,
  ) : super([]);

  final SupabaseDatabaseService _dbService;
  final String? _userId;

  Future<void> fetchReservations() async {
    final userId = _userId;

    if (userId == null || userId.isEmpty) {
      state = [];
      return;
    }

    try {
      final reservations = await _dbService.getReservations(userId);
      state = reservations;
    } catch (e) {
      throw Exception('Não foi possível carregar as reservas: $e');
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

    state = [newReservation, ...state];

    return newReservation;
  }

  void cancelReservation(String id) {
    // Não remover apenas da lista local:
    // o cancelamento também precisa de ser persistido no Supabase.
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
