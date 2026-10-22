import 'package:flutter/material.dart';

import '../../domain/entities/candle.dart';
import '../../domain/entities/encoded_result.dart';

/// A scrollable DataTable showing, for every one of the 120 candles,
/// EXACTLY how its symbol was calculated: the raw Open/Close it came from,
/// the body%/gap% derived from them, and a plain-English sentence
/// comparing that number against the calibrated threshold to show why the
/// symbol came out U, D, F, or G. Nothing here is a new calculation --
/// every number is already stored in [trace] / [candles]; this widget
/// only narrates it (presentation-layer formatting, not a new business
/// rule, so the Data layer's `encodeCandles` stays the single source of
/// truth -- DRY).
class EncodingTraceTable extends StatelessWidget {
  final List<EncodingTrace> trace;
  final List<Candle> candles;
  final double bodyThreshold;
  final double gapThreshold;

  const EncodingTraceTable({
    super.key,
    required this.trace,
    required this.candles,
    required this.bodyThreshold,
    required this.gapThreshold,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Open'), numeric: true),
          DataColumn(label: Text('Close'), numeric: true),
          DataColumn(label: Text('Gap %'), numeric: true),
          DataColumn(label: Text('Body %'), numeric: true),
          DataColumn(label: Text('Symbol')),
          DataColumn(label: Text('How it was calculated')),
        ],
        rows: List.generate(trace.length, (i) {
          final t = trace[i];
          final candle = i < candles.length ? candles[i] : null;
          return DataRow(cells: [
            DataCell(Text('${i + 1}')),
            DataCell(Text(t.date)),
            DataCell(Text(candle != null ? candle.open.toStringAsFixed(2) : '—')),
            DataCell(Text(candle != null ? candle.close.toStringAsFixed(2) : '—')),
            DataCell(Text('${(t.gapPercent * 100).toStringAsFixed(2)}%')),
            DataCell(Text('${(t.bodyPercent * 100).toStringAsFixed(2)}%')),
            DataCell(_symbolChip(t.symbol)),
            DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text(
                  _explain(i, t, candle),
                  style: const TextStyle(fontSize: 11),
                  softWrap: true,
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }

  /// Narrates, in plain words, exactly which comparison produced
  /// `t.symbol` -- mirrors `EncodingRepositoryImpl.encodeCandles` /
  /// `_classifyBody` step for step, reusing the SAME numbers already
  /// stored in [t] rather than recomputing anything.
  String _explain(int i, EncodingTrace t, Candle? candle) {
    final bodyPct = (t.bodyPercent * 100).toStringAsFixed(2);
    final bodyThreshPct = (bodyThreshold * 100).toStringAsFixed(2);
    final gapPct = (t.gapPercent * 100).toStringAsFixed(2);
    final gapThreshPct = (gapThreshold * 100).toStringAsFixed(2);

    if (i == 0) {
      return 'First candle, no previous close → judged by body only. '
          '${_bodyExplain(candle, bodyPct, bodyThreshPct, t.symbol)}';
    }

    if (t.symbol == 'G') {
      return 'gap $gapPct% > threshold $gapThreshPct% → G '
          '(a gap always wins over the body check)';
    }

    return 'gap $gapPct% ≤ threshold $gapThreshPct%, so check body: '
        '${_bodyExplain(candle, bodyPct, bodyThreshPct, t.symbol)}';
  }

  String _bodyExplain(
    Candle? candle,
    String bodyPct,
    String bodyThreshPct,
    String symbol,
  ) {
    if (symbol == 'F') {
      return 'body $bodyPct% ≤ threshold $bodyThreshPct% → flat (F)';
    }
    final direction = candle == null
        ? ''
        : (candle.close >= candle.open
            ? 'close(${candle.close.toStringAsFixed(2)}) ≥ open(${candle.open.toStringAsFixed(2)}), '
            : 'open(${candle.open.toStringAsFixed(2)}) > close(${candle.close.toStringAsFixed(2)}), ');
    return '$direction'
        'body $bodyPct% > threshold $bodyThreshPct% → '
        '${symbol == 'U' ? 'up (U)' : 'down (D)'}';
  }

  Widget _symbolChip(String symbol) {
    final color = switch (symbol) {
      'U' => const Color(0xFF26A69A),
      'D' => const Color(0xFFEF5350),
      'F' => const Color(0xFF78909C),
      'G' => const Color(0xFFFFCA28),
      _ => Colors.white,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        symbol,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
