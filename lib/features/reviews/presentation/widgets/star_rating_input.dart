import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class StarRatingInput extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final String label;
  final String description;

  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    required this.label,
    required this.description,
  });

  String _getRatingText(double value) {
    if (value >= 5) return 'Excelente ⭐⭐⭐⭐⭐';
    if (value >= 4) return 'Muito Bom ⭐⭐⭐⭐';
    if (value >= 3) return 'Satisfatório ⭐⭐⭐';
    if (value >= 2) return 'Fraco ⭐⭐ (Requer Moderação)';
    if (value >= 1) return 'Péssimo ⭐ (Requer Moderação)';
    return 'Selecione de 1 a 5 estrelas';
  }

  Color _getRatingColor(double value) {
    if (value >= 4) return Colors.amber.shade700;
    if (value == 3) return Colors.orange.shade700;
    if (value > 0) return Colors.red.shade600;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final isLowRating = rating > 0 && rating <= 2;
    final ratingColor = _getRatingColor(rating);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isLowRating
              ? Colors.red.shade200
              : AppColors.borderLight,
          width: isLowRating ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (index) {
                  final starValue = index + 1.0;
                  final isSelected = starValue <= rating;

                  return InkWell(
                    onTap: () => onRatingChanged(starValue),
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 5,
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 36,
                        color: isSelected
                            ? ratingColor
                            : Colors.grey.shade300,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: rating > 0
                    ? ratingColor.withValues(alpha: 0.10)
                    : const Color(0xFFF3F6F4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getRatingText(rating),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ratingColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
