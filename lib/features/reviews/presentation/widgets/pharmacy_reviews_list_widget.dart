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
  State<PharmacyReviewsListWidget> createState() =>
      _PharmacyReviewsListWidgetState();
}

class _PharmacyReviewsListWidgetState
    extends State<PharmacyReviewsListWidget> {
  final SupabaseDatabaseService _db = SupabaseDatabaseService();

  List<ReviewModel> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews =
          await _db.getReviewsForPharmacy(widget.pharmacyId);

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _reviews = [];
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) {
          final starNumber = index + 1;

          return Icon(
            starNumber <= rating
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            size: 19,
            color: const Color(0xFFF5A623),
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final comment = review.pharmacyComment?.trim() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8EFEA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF173B57),
                      ),
                    ),
                    const SizedBox(height: 5),
                    _buildStars(review.pharmacyRating),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDate(review.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF718078),
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBF9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                comment,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF45564D),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8EFEA),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 44,
            color: AppColors.primary,
          ),
          SizedBox(height: 12),
          Text(
            'Ainda não existem avaliações.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF52645A),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'As avaliações dos clientes serão apresentadas aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF89958E),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.rate_review_rounded,
                color: AppColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                'Avaliações da ${widget.pharmacyName}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF173B57),
                ),
              ),
            ),
            IconButton(
              onPressed: _loadReviews,
              tooltip: 'Atualizar',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF0F7F2),
                foregroundColor: AppColors.primary,
              ),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          )
        else if (_reviews.isEmpty)
          _buildEmptyState()
        else
          Column(
            children: _reviews.map(_buildReviewCard).toList(),
          ),
      ],
    );
  }
}
