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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rating > 0 && rating <= 2 ? Colors.red.shade300 : AppColors.borderLight,
          width: rating > 0 && rating <= 2 ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Text(
                _getRatingText(rating),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getRatingColor(rating),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1.0;
              final isSelected = starValue <= rating;
              return InkWell(
                onTap: () => onRatingChanged(starValue),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 36,
                    color: isSelected ? _getRatingColor(rating) : Colors.grey.shade400,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
