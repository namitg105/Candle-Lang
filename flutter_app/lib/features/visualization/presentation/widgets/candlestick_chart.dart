import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../encoding/domain/entities/candle.dart';

/// Custom-painted OHLC candlestick chart widget.
///
/// Uses [CustomPainter] to draw wicks and bodies directly on canvas.
/// Scrolls horizontally when candles exceed the visible width.
class CandlestickChart extends StatelessWidget {
  final List<Candle> candles;
  final double height;

  const CandlestickChart({
    super.key,
    required this.candles,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No candle data')),
      );
    }

    // Each candle gets a fixed width slot; scroll if needed.
    const candleSlotWidth = 6.0;
    final totalWidth = candles.length * candleSlotWidth;

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: CustomPaint(
          size: Size(math.max(totalWidth, 300), height),
          painter: _CandlestickPainter(candles: candles),
        ),
      ),
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<Candle> candles;

  _CandlestickPainter({required this.candles});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    // Compute price range for Y-axis scaling.
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;
    for (final c in candles) {
      if (c.low < minPrice) minPrice = c.low;
      if (c.high > maxPrice) maxPrice = c.high;
    }
    final priceRange = maxPrice - minPrice;
    if (priceRange == 0) return;

    // Leave 5% padding top and bottom.
    final paddedMin = minPrice - priceRange * 0.05;
    final paddedMax = maxPrice + priceRange * 0.05;
    final paddedRange = paddedMax - paddedMin;

    final slotWidth = size.width / candles.length;
    final bodyWidth = slotWidth * 0.6;

    // Draw grid lines.
    _drawGrid(canvas, size, paddedMin, paddedMax);

    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = i * slotWidth + slotWidth / 2;

      // Y conversion: top of canvas = maxPrice, bottom = minPrice.
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

      // Draw wick (high-low line).
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), paint);

      // Draw body (open-close rectangle).
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
    return oldDelegate.candles != candles;
  }
}
