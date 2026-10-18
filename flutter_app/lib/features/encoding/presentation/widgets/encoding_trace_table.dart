import 'package:flutter/material.dart';

import '../../domain/entities/encoded_result.dart';

/// A scrollable DataTable showing the per-candle encoding trace.
class EncodingTraceTable extends StatelessWidget {
  final List<EncodingTrace> trace;

  const EncodingTraceTable({super.key, required this.trace});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Symbol')),
          DataColumn(label: Text('Gap %'), numeric: true),
          DataColumn(label: Text('Body %'), numeric: true),
        ],
        rows: List.generate(trace.length, (i) {
          final t = trace[i];
          return DataRow(cells: [
            DataCell(Text('${i + 1}')),
            DataCell(Text(t.date)),
            DataCell(_symbolChip(t.symbol)),
            DataCell(Text('${(t.gapPercent * 100).toStringAsFixed(2)}%')),
            DataCell(Text('${(t.bodyPercent * 100).toStringAsFixed(2)}%')),
          ]);
        }),
      ),
    );
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
