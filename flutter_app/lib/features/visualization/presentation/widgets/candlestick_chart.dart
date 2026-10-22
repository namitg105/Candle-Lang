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

  /// The encoded alphabet symbol for each candle, in the same order as
  /// [candles] (so `encodedSymbols[i]` describes `candles[i]`). When this
  /// is given and its length matches [candles], every candle is colored
  /// by what the encoder actually classified it as (U/D/F/G) instead of
  /// the simpler bullish/bearish-only coloring.
  final String? encodedSymbols;

  const CandlestickChart({
    super.key,
    required this.candles,
    this.height = 260,
    this.highlightStart,
    this.highlightEnd,
    this.highlightColor,
    this.encodedSymbols,
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
    final colorBySymbol =
        encodedSymbols != null && encodedSymbols!.length == candles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (colorBySymbol) _buildColorKey(),
        if (colorBySymbol) const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: CustomPaint(
              size: Size(math.max(totalWidth, 300), height),
              painter: _CandlestickPainter(
                candles: candles,
                encodedSymbols: colorBySymbol ? encodedSymbols : null,
                highlightStart: highlightStart,
                highlightEnd: highlightEnd,
                highlightColor: highlightColor ?? AppTheme.bullishColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// U/D/F/G -> color legend, shown only when candles are colored by
  /// their encoded symbol instead of plain bullish/bearish.
  Widget _buildColorKey() {
    Widget entry(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        );

    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        entry(AppTheme.bullishColor, 'U — up'),
        entry(AppTheme.bearishColor, 'D — down'),
        entry(AppTheme.neutralColor, 'F — flat'),
        entry(AppTheme.gapColor, 'G — gap'),
      ],
    );
  }
}

// Height reserved along the bottom for the x-axis time labels.
const double _kXAxisHeight = 16.0;

class _CandlestickPainter extends CustomPainter {
  final List<Candle> candles;
  final String? encodedSymbols;
  final int? highlightStart;
  final int? highlightEnd;
  final Color highlightColor;

  _CandlestickPainter({
    required this.candles,
    this.encodedSymbols,
    this.highlightStart,
    this.highlightEnd,
    required this.highlightColor,
  });

  /// Maps one encoded alphabet symbol to the color it's drawn in.
  /// Falls back to plain bullish/bearish if the symbol isn't recognized
  /// (keeps the chart rendering something sensible either way).
  Color _colorForSymbol(String symbol, bool isBullish) {
    switch (symbol) {
      case 'U':
        return AppTheme.bullishColor;
      case 'D':
        return AppTheme.bearishColor;
      case 'F':
        return AppTheme.neutralColor;
      case 'G':
        return AppTheme.gapColor;
      default:
        return isBullish ? AppTheme.bullishColor : AppTheme.bearishColor;
    }
  }

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

    // Reserve a strip along the bottom for "what time did this candle
    // land" labels -- the price area (grid, wicks, bodies) is drawn only
    // above it, in a slightly shorter height.
    final chartHeight = size.height - _kXAxisHeight;

    _drawGrid(canvas, Size(size.width, chartHeight), paddedMin, paddedMax);
    _drawTimeAxis(canvas, size, chartHeight, slotWidth);

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
          Rect.fromLTWH(left, 0, width, chartHeight),
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
          Rect.fromLTWH(left, 0, width, chartHeight),
          const Radius.circular(6),
        ),
        borderPaint,
      );
    }

    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = i * slotWidth + slotWidth / 2;

      double toY(double price) =>
          chartHeight - ((price - paddedMin) / paddedRange) * chartHeight;

      final highY = toY(c.high);
      final lowY = toY(c.low);
      final openY = toY(c.open);
      final closeY = toY(c.close);

      final color = encodedSymbols != null
          ? _colorForSymbol(encodedSymbols![i], c.isBullish)
          : (c.isBullish ? AppTheme.bullishColor : AppTheme.bearishColor);
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

  /// Draws a handful of evenly-spaced "HH:mm" labels along the bottom so
  /// it's clear what time each candle landed, without cramming a label
  /// under every single candle (120 of them would overlap into mush).
  void _drawTimeAxis(Canvas canvas, Size size, double chartHeight, double slotWidth) {
    if (candles.isEmpty) return;

    // Roughly one label per 70px of width, at least 2, never more than
    // one per candle.
    final maxLabels = (size.width / 70).floor().clamp(2, candles.length);
    final step = (candles.length / maxLabels).ceil().clamp(1, candles.length);

    final tickPaint = Paint()
      ..color = AppTheme.gridColor
      ..strokeWidth = 0.5;

    for (var i = 0; i < candles.length; i += step) {
      final x = i * slotWidth + slotWidth / 2;

      canvas.drawLine(Offset(x, chartHeight), Offset(x, chartHeight + 3), tickPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: _timeLabelFor(candles[i].date),
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontFamily: 'monospace'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Clamp so the first/last label doesn't spill past the chart edge.
      final labelX = x - tp.width / 2;
      final clampedX = labelX.clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(clampedX, chartHeight + 5));
    }
  }

  /// Pulls "HH:mm" out of a candle's date string. The app's data sources
  /// use "YYYY-MM-DD HH:mm:ss" (the Twelve Data API's `datetime` field);
  /// this handles an ISO "T" separator too and falls back to the raw
  /// string if neither shape matches, so a chart never breaks over an
  /// unexpected date format.
  String _timeLabelFor(String date) {
    final parts = date.contains('T') ? date.split('T') : date.split(' ');
    if (parts.length < 2) return date;
    final time = parts[1];
    return time.length >= 5 ? time.substring(0, 5) : time;
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.encodedSymbols != encodedSymbols ||
        oldDelegate.highlightStart != highlightStart ||
        oldDelegate.highlightEnd != highlightEnd;
  }
}
