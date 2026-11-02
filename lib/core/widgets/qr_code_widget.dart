import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../constants/app_colors.dart';

class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color color;
  final Color backgroundColor;

  const QrCodeWidget({
    super.key,
    required this.data,
    this.size = 180,
    this.color = AppColors.primaryDark,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedData = data.trim();

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: normalizedData.isEmpty
          ? const Center(
              child: Text(
                'Código indisponível',
                textAlign: TextAlign.center,
              ),
            )
          : QrImageView(
              data: normalizedData,
              version: QrVersions.auto,
              size: size - 24,
              backgroundColor: backgroundColor,
              foregroundColor: color,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              gapless: true,
            ),
    );
  }
}
