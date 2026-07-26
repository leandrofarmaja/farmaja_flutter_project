import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_database_service.dart';
import '../../domain/review_model.dart';

class PharmacyReviewsListWidget extends StatefulWidget {
  final String pharmacyId;
  final String pharmacyName;

  const PharmacyReviewsListWidget({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
  });

  @override
  State<PharmacyReviewsListWidget> createState() => _PharmacyReviewsListWidgetState();
}

class _PharmacyReviewsListWidgetState extends State<PharmacyReviewsListWidget> {
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() async {
    final db = SupabaseDatabaseService();
    final list = await db.getReviewsForPharmacy(widget.pharmacyId);
    if (mounted) {
      setState(() {
        _reviews = list;
        _isLoading = false;
      });
    }
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 4.8;
    final sum = _reviews.fold(0.0, (s, r) => s + r.pharmacyRating);
    return sum / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 32),
                    ],
                  ),
                  Text(
                    '${_reviews.length} ${_reviews.length == 1 ? 'avaliação pública' : 'avaliações públicas'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
              const Spacer(),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Verificadas FarmaJá',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                  ),
                  Text(
                    'Apenas utentes com reservas concluídas',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Ainda não existem avaliações públicas para esta farmácia. Seja o primeiro a avaliar após uma reserva!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final rev = _reviews[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        Text(
                          rev.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Row(
                          children: List.generate(5, (s) {
                            return Icon(
                              s < rev.pharmacyRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 16,
                              color: s < rev.pharmacyRating ? Colors.amber : Colors.grey.shade300,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (rev.pharmacyComment != null && rev.pharmacyComment!.isNotEmpty) ...[
                      Text(
                        '"${rev.pharmacyComment}"',
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reserva #${rev.reservationId}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          '${rev.createdAt.day}/${rev.createdAt.month}/${rev.createdAt.year}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
