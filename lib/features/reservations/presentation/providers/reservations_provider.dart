import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/reservation_model.dart';

class ReservationsNotifier extends StateNotifier<List<ReservationModel>> {
  final SupabaseDatabaseService _dbService;
  final String _userId;

  ReservationsNotifier(this._dbService, this._userId) : super([]) {
    fetchReservations();
  }

  Future<void> fetchReservations() async {
    final list = await _dbService.getReservations(_userId);
    state = list;
  }

  Future<void> addReservation({
    required String medicineName,
    required String pharmacyName,
    required double totalPriceKz,
    required bool prescriptionUploaded,
  }) async {
    final newRes = await _dbService.createReservation(
      userId: _userId,
      medicineName: medicineName,
      pharmacyName: pharmacyName,
      totalPriceKz: totalPriceKz,
      prescriptionUploaded: prescriptionUploaded,
    );

    state = [newRes, ...state];
  }

  void cancelReservation(String id) {
    state = state.where((r) => r.id != id).toList();
  }

  void markReservationReviewed(String reservationId, double rating) {
    state = state.map((r) {
      if (r.id == reservationId) {
        return r.copyWith(isReviewed: true, reviewRating: rating);
      }
      return r;
    }).toList();
  }
}

final reservationsProvider =
    StateNotifierProvider<ReservationsNotifier, List<ReservationModel>>((ref) {
  final dbService = ref.watch(supabaseDatabaseServiceProvider);
  final user = ref.watch(authProvider).user;
  final userId = user?.id ?? 'usr-supabase-default';
  return ReservationsNotifier(dbService, userId);
});
