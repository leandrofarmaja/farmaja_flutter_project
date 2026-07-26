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
        border: Border.all(color: AppColors.borderLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size - 24, size - 24),
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

  _QrPainter({required this.data, required this.codeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = codeColor
      ..style = PaintingStyle.fill;

    const gridSize = 15;
    final cellSize = size.width / gridSize;

    // Deterministic pseudo-QR pattern derived from hashed data string
    final bytes = utf8.encode(data);
    int seed = 0;
    for (var b in bytes) {
      seed = (seed * 31 + b) & 0x7FFFFFFF;
    }

    bool isBitSet(int r, int c) {
      // Finder patterns top-left, top-right, bottom-left
      if ((r < 4 && c < 4) || (r < 4 && c >= gridSize - 4) || (r >= gridSize - 4 && c < 4)) {
        // Outer border
        if (r == 0 || r == 3 || c == 0 || c == 3 ||
            r == gridSize - 1 || r == gridSize - 4 ||
            c == gridSize - 1 || c == gridSize - 4) {
          return true;
        }
        // Inner center
        if ((r >= 1 && r <= 2 && c >= 1 && c <= 2) ||
            (r >= 1 && r <= 2 && c >= gridSize - 3 && c <= gridSize - 2) ||
            (r >= gridSize - 3 && r <= gridSize - 2 && c >= 1 && c <= 2)) {
          return true;
        }
        return false;
      }

      // Timing pattern
      if (r == 6 || c == 6) {
        return (r + c) % 2 == 0;
      }

      // Data bit pseudo matrix derived from string seed
      final pos = r * gridSize + c;
      final hash = (seed ^ (pos * 2654435761)) & 0x7FFFFFFF;
      return (hash % 3) == 0 || (hash % 5) == 0;
    }

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (isBitSet(r, c)) {
          final rect = Rect.fromLTWH(
            c * cellSize + 0.5,
            r * cellSize + 0.5,
            cellSize - 1,
            cellSize - 1,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.codeColor != codeColor;
  }
}
