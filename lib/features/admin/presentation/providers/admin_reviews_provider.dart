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
    this.averageAppRating = 5.0,
    this.averagePharmacyRating = 5.0,
    required this.bestPharmacies,
    required this.lowestPharmacies,
    required this.appStarDistribution,
    required this.pharmacyStarDistribution,
  });

  List<ReviewModel> get pendingModerationReviews =>
      reviews.where((r) => r.status == 'pending_moderation').toList();

  int get unreadNotificationsCount => notifications.where((n) => !n.isRead).length;

  AdminReviewsState copyWith({
    List<ReviewModel>? reviews,
    List<AdminNotificationModel>? notifications,
    bool? isLoading,
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
      averageAppRating: averageAppRating ?? this.averageAppRating,
      averagePharmacyRating: averagePharmacyRating ?? this.averagePharmacyRating,
      bestPharmacies: bestPharmacies ?? this.bestPharmacies,
      lowestPharmacies: lowestPharmacies ?? this.lowestPharmacies,
      appStarDistribution: appStarDistribution ?? this.appStarDistribution,
      pharmacyStarDistribution: pharmacyStarDistribution ?? this.pharmacyStarDistribution,
    );
  }
}

class AdminReviewsNotifier extends StateNotifier<AdminReviewsState> {
  final SupabaseDatabaseService _db;

  AdminReviewsNotifier(this._db)
      : super(AdminReviewsState(
          reviews: [],
          notifications: [],
          bestPharmacies: [],
          lowestPharmacies: [],
          appStarDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
          pharmacyStarDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        )) {
    loadReviewsData();
  }

  Future<void> loadReviewsData() async {
    state = state.copyWith(isLoading: true);

    final allReviews = await _db.getAllReviews();
    final notifs = await _db.getAdminNotifications();
    final pharmacies = await _db.getPharmacies();

    // Calculate App Rating & Pharmacy Ratings
    double totalApp = 0;
    double totalPharm = 0;

    Map<int, int> appStars = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    Map<int, int> pharmStars = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (var r in allReviews) {
      totalApp += r.appRating;
      totalPharm += r.pharmacyRating;

      final appKey = r.appRating.round().clamp(1, 5);
      final pharmKey = r.pharmacyRating.round().clamp(1, 5);

      appStars[appKey] = (appStars[appKey] ?? 0) + 1;
      pharmStars[pharmKey] = (pharmStars[pharmKey] ?? 0) + 1;
    }

    final avgApp = allReviews.isNotEmpty ? totalApp / allReviews.length : 4.8;
    final avgPharm = allReviews.isNotEmpty ? totalPharm / allReviews.length : 4.7;

    // Aggregate Ratings per Pharmacy
    Map<String, List<double>> pharmRatingsMap = {};
    Map<String, String> pharmNamesMap = {};

    for (var p in pharmacies) {
      pharmNamesMap[p.id] = p.name;
    }

    for (var r in allReviews) {
      if (r.status == 'approved' || r.status == 'pending_moderation') {
        pharmRatingsMap.putIfAbsent(r.pharmacyId, () => []).add(r.pharmacyRating);
        pharmNamesMap[r.pharmacyId] = r.pharmacyName;
      }
    }

    List<PharmacyRatingStat> statsList = [];
    pharmRatingsMap.forEach((id, ratings) {
      final name = pharmNamesMap[id] ?? 'Farmácia';
      final avg = ratings.fold(0.0, (s, e) => s + e) / ratings.length;
      statsList.add(PharmacyRatingStat(
        pharmacyId: id,
        pharmacyName: name,
        averageRating: double.parse(avg.toStringAsFixed(1)),
        totalReviews: ratings.length,
      ));
    });

    // Sort Best & Lowest
    statsList.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    final best = List<PharmacyRatingStat>.from(statsList.take(5));

    final lowestSorted = List<PharmacyRatingStat>.from(statsList);
    lowestSorted.sort((a, b) => a.averageRating.compareTo(b.averageRating));
    final lowest = List<PharmacyRatingStat>.from(lowestSorted.take(5));

    state = state.copyWith(
      reviews: allReviews,
      notifications: notifs,
      isLoading: false,
      averageAppRating: double.parse(avgApp.toStringAsFixed(1)),
      averagePharmacyRating: double.parse(avgPharm.toStringAsFixed(1)),
      bestPharmacies: best,
      lowestPharmacies: lowest,
      appStarDistribution: appStars,
      pharmacyStarDistribution: pharmStars,
    );
  }

  Future<void> moderateReview(String reviewId, String status, {String? note}) async {
    await _db.moderateReview(reviewId: reviewId, status: status, note: note);
    await loadReviewsData();
  }

  Future<void> markNotificationRead(String id) async {
    await _db.markAdminNotificationRead(id);
    await loadReviewsData();
  }
}

final adminReviewsProvider =
    StateNotifierProvider<AdminReviewsNotifier, AdminReviewsState>((ref) {
  final db = ref.watch(supabaseDatabaseServiceProvider);
  return AdminReviewsNotifier(db);
});
