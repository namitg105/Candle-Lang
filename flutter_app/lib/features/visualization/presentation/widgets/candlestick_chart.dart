import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../encoding/domain/entities/candle.dart';

/// Custom-painted OHLC candlestick chart with pattern highlight support.
class CandlestickChart extends StatelessWidget {
  final List<Candle> candles;
  final double height;
  final int? highlightStart;
  final int? highlightEnd;
  final Color? highlightColor;

  const CandlestickChart({
    super.key,
    required this.candles,
    this.height = 260,
    this.highlightStart,
    this.highlightEnd,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No candle data')),
      );
    }

    const candleSlotWidth = 7.0;
    final totalWidth = candles.length * candleSlotWidth;

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: CustomPaint(
          size: Size(math.max(totalWidth, 300), height),
          painter: _CandlestickPainter(
            candles: candles,
            highlightStart: highlightStart,
            highlightEnd: highlightEnd,
            highlightColor: highlightColor ?? AppTheme.bullishColor,
          ),
        ),
      ),
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<Candle> candles;
  final int? highlightStart;
  final int? highlightEnd;
  final Color highlightColor;

  _CandlestickPainter({
    required this.candles,
    this.highlightStart,
    this.highlightEnd,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;
    for (final c in candles) {
      if (c.low < minPrice) minPrice = c.low;
      if (c.high > maxPrice) maxPrice = c.high;
    }
    final priceRange = maxPrice - minPrice;
    if (priceRange == 0) return;

    final paddedMin = minPrice - priceRange * 0.05;
    final paddedMax = maxPrice + priceRange * 0.05;
    final paddedRange = paddedMax - paddedMin;

    final slotWidth = size.width / candles.length;
    final bodyWidth = slotWidth * 0.65;

    _drawGrid(canvas, size, paddedMin, paddedMax);

    // Draw match highlight zone if selected
    if (highlightStart != null &&
        highlightEnd != null &&
        highlightStart! >= 0 &&
        highlightEnd! <= candles.length &&
        highlightStart! < highlightEnd!) {
      final left = highlightStart! * slotWidth;
      final width = (highlightEnd! - highlightStart!) * slotWidth;

      final highlightPaint = Paint()
        ..color = highlightColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, 0, width, size.height),
          const Radius.circular(6),
        ),
        highlightPaint,
      );

      final borderPaint = Paint()
        ..color = highlightColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, 0, width, size.height),
          const Radius.circular(6),
        ),
        borderPaint,
      );
    }

    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = i * slotWidth + slotWidth / 2;

      double toY(double price) =>
          size.height - ((price - paddedMin) / paddedRange) * size.height;

      final highY = toY(c.high);
      final lowY = toY(c.low);
      final openY = toY(c.open);
      final closeY = toY(c.close);

      final color = c.isBullish ? AppTheme.bullishColor : AppTheme.bearishColor;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1;

      // Draw wick
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), paint);

      // Draw body
      final bodyTop = math.min(openY, closeY);
      final bodyBottom = math.max(openY, closeY);
      final bodyHeight = math.max(bodyBottom - bodyTop, 1.0);

      final bodyPaint = Paint()
        ..color = color
        ..style = c.isBullish ? PaintingStyle.stroke : PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(x - bodyWidth / 2, bodyTop, bodyWidth, bodyHeight),
        bodyPaint,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size, double minPrice, double maxPrice) {
    final gridPaint = Paint()
      ..color = AppTheme.gridColor
      ..strokeWidth = 0.5;

    const gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y = size.height * i / gridLines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.highlightStart != highlightStart ||
        oldDelegate.highlightEnd != highlightEnd;
  }
}
