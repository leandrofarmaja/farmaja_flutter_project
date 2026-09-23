import 'dart:convert';

import 'package:flutter/material.dart';

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
      child: CustomPaint(
        size: Size(
          size - 24,
          size - 24,
        ),
        painter: _QrPainter(
          data: data,
          codeColor: color,
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final String data;
  final Color codeColor;

  _QrPainter({
    required this.data,
    required this.codeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = codeColor
      ..style = PaintingStyle.fill;

    const gridSize = 15;
    final cellSize = size.width / gridSize;

    final bytes = utf8.encode(data);

    int seed = 0;

    for (var b in bytes) {
      seed = (seed * 31 + b) & 0x7FFFFFFF;
    }

    bool isBitSet(int row, int column) {
      // Marcador superior esquerdo
      if (row < 4 && column < 4) {
        if (row == 0 ||
            row == 3 ||
            column == 0 ||
            column == 3) {
          return true;
        }

        if (row >= 1 &&
            row <= 2 &&
            column >= 1 &&
            column <= 2) {
          return true;
        }

        return false;
      }

      // Marcador superior direito
      if (row < 4 && column >= gridSize - 4) {
        if (row == 0 ||
            row == 3 ||
            column == gridSize - 1 ||
            column == gridSize - 4) {
          return true;
        }

        if (row >= 1 &&
            row <= 2 &&
            column >= gridSize - 3 &&
            column <= gridSize - 2) {
          return true;
        }

        return false;
      }

      // Marcador inferior esquerdo
      if (row >= gridSize - 4 && column < 4) {
        if (row == gridSize - 1 ||
            row == gridSize - 4 ||
            column == 0 ||
            column == 3) {
          return true;
        }

        if (row >= gridSize - 3 &&
            row <= gridSize - 2 &&
            column >= 1 &&
            column <= 2) {
          return true;
        }

        return false;
      }

      // Linha e coluna de sincronização
      if (row == 6 || column == 6) {
        return (row + column) % 2 == 0;
      }

      final position = row * gridSize + column;

      final hash =
          (seed ^ (position * 2654435761)) & 0x7FFFFFFF;

      return (hash % 3) == 0 || (hash % 5) == 0;
    }

    for (int row = 0; row < gridSize; row++) {
      for (int column = 0; column < gridSize; column++) {
        if (isBitSet(row, column)) {
          final rect = Rect.fromLTWH(
            column * cellSize + 0.5,
            row * cellSize + 0.5,
            cellSize - 1,
            cellSize - 1,
          );

          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect,
              const Radius.circular(1.5),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.codeColor != codeColor;
  }
}
