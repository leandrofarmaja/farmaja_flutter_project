
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_database_service.dart';
import '../../../pharmacies/domain/pharmacy_model.dart';
import '../../../reviews/domain/review_model.dart';
import '../../domain/admin_notification_model.dart';

class PharmacyRatingStat {
  final String pharmacyId;
  final String pharmacyName;
  final double averageRating;
  final int totalReviews;

  PharmacyRatingStat({
    required this.pharmacyId,
    required this.pharmacyName,
    required this.averageRating,
    required this.totalReviews,
  });
}

class AdminReviewsState {
  final List<ReviewModel> reviews;
  final List<AdminNotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final double averageAppRating;
  final double averagePharmacyRating;
  final List<PharmacyRatingStat> bestPharmacies;
  final List<PharmacyRatingStat> lowestPharmacies;
  final Map<int, int> appStarDistribution;
  final Map<int, int> pharmacyStarDistribution;

  AdminReviewsState({
    required this.reviews,
    required this.notifications,
    this.isLoading = false,
    this.error,
    this.averageAppRating = 0,
    this.averagePharmacyRating = 0,
    required this.bestPharmacies,
    required this.lowestPharmacies,
    required this.appStarDistribution,
    required this.pharmacyStarDistribution,
  });

  List<ReviewModel> get pendingModerationReviews =>
      reviews.where((r) => r.status == 'pending_moderation').toList();

  int get unreadNotificationsCount =>
      notifications.where((n) => !n.isRead).length;

  AdminReviewsState copyWith({
    List<ReviewModel>? reviews,
    List<AdminNotificationModel>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
    double? averageAppRating,
    double? averagePharmacyRating,
    List<PharmacyRatingStat>? bestPharmacies,
    List<PharmacyRatingStat>? lowestPharmacies,
    Map<int, int>? appStarDistribution,
    Map<int, int>? pharmacyStarDistribution,
  }) {
    return AdminReviewsState(
      reviews: reviews ?? this.reviews,
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      averageAppRating: averageAppRating ?? this.averageAppRating,
      averagePharmacyRating:
          averagePharmacyRating ?? this.averagePharmacyRating,
      bestPharmacies: bestPharmacies ?? this.bestPharmacies,
      lowestPharmacies: lowestPharmacies ?? this.lowestPharmacies,
      appStarDistribution:
          appStarDistribution ?? this.appStarDistribution,
      pharmacyStarDistribution:
          pharmacyStarDistribution ?? this.pharmacyStarDistribution,
    );
  }
}

class AdminReviewsNotifier extends StateNotifier<AdminReviewsState> {
  final SupabaseDatabaseService _db;

  AdminReviewsNotifier(this._db)
      : super(
          AdminReviewsState(
            reviews: [],
            notifications: [],
            bestPharmacies: [],
            lowestPharmacies: [],
            appStarDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
            pharmacyStarDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
          ),
        ) {
    loadReviewsData();
  }

  Future<void> loadReviewsData() async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final results = await Future.wait<dynamic>([
        _db.getAllReviews(),
        _db.getPharmacies(),
      ]).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception(
            'O carregamento excedeu 20 segundos. '
            'Verifica a ligação ao Supabase.',
          );
        },
      );

      final allReviews = results[0] as List<ReviewModel>;
      final pharmacies = results[1] as List<PharmacyModel>;

      final approvedReviews = allReviews
          .where((review) => review.status == 'approved')
          .toList();

      double totalApp = 0;
      double totalPharm = 0;

      final appStars = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      final pharmStars = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

      for (final review in approvedReviews) {
        totalApp += review.appRating;
        totalPharm += review.pharmacyRating;

        final appKey = review.appRating.round().clamp(1, 5);
        final pharmKey = review.pharmacyRating.round().clamp(1, 5);

        appStars[appKey] = (appStars[appKey] ?? 0) + 1;
        pharmStars[pharmKey] = (pharmStars[pharmKey] ?? 0) + 1;
      }

      final avgApp = approvedReviews.isNotEmpty
          ? totalApp / approvedReviews.length
          : 0.0;

      final avgPharm = approvedReviews.isNotEmpty
          ? totalPharm / approvedReviews.length
          : 0.0;

      final pharmacyNames = <String, String>{
        for (final pharmacy in pharmacies) pharmacy.id: pharmacy.name,
      };

      final ratingsByPharmacy = <String, List<double>>{};

      for (final review in approvedReviews) {
        ratingsByPharmacy
            .putIfAbsent(review.pharmacyId, () => [])
            .add(review.pharmacyRating);

        pharmacyNames[review.pharmacyId] = review.pharmacyName;
      }

      final stats = <PharmacyRatingStat>[];

      ratingsByPharmacy.forEach((id, ratings) {
        if (ratings.isEmpty) return;

        final average =
            ratings.fold<double>(0, (sum, rating) => sum + rating) /
                ratings.length;

        stats.add(
          PharmacyRatingStat(
            pharmacyId: id,
            pharmacyName: pharmacyNames[id] ?? 'Farmácia',
            averageRating: double.parse(average.toStringAsFixed(1)),
            totalReviews: ratings.length,
          ),
        );
      });

      stats.sort(
        (a, b) => b.averageRating.compareTo(a.averageRating),
      );

      final best = stats.take(5).toList();

      final lowest = List<PharmacyRatingStat>.from(stats)
        ..sort(
          (a, b) => a.averageRating.compareTo(b.averageRating),
        );

      state = state.copyWith(
        reviews: allReviews,
        notifications: [],
        isLoading: false,
        averageAppRating: double.parse(avgApp.toStringAsFixed(1)),
        averagePharmacyRating:
            double.parse(avgPharm.toStringAsFixed(1)),
        bestPharmacies: best,
        lowestPharmacies: lowest.take(5).toList(),
        appStarDistribution: appStars,
        pharmacyStarDistribution: pharmStars,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Não foi possível carregar os dados administrativos: $e',
      );
    }
  }

  Future<void> moderateReview(
    String reviewId,
    String status, {
    String? note,
  }) async {
    if (status != 'approved' && status != 'rejected') {
      throw ArgumentError('Estado de moderação inválido.');
    }

    try {
      await _db.moderateReview(
        reviewId: reviewId,
        status: status,
        note: note,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Não foi possível moderar a avaliação: $e',
      );
      rethrow;
    }

    await loadReviewsData();
  }

  Future<void> markNotificationRead(String id) async {
    state = state.copyWith(
      error: 'A gestão de notificações administrativas ainda não está implementada.',
    );
  }
}

final adminReviewsProvider =
    StateNotifierProvider<AdminReviewsNotifier, AdminReviewsState>((ref) {
  final db = ref.watch(supabaseDatabaseServiceProvider);
  return AdminReviewsNotifier(db);
});
