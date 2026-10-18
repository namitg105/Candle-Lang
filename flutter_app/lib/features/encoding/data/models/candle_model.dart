import 'package:csv/csv.dart';

import '../../domain/entities/candle.dart';

/// Data-layer model that extends the domain [Candle] entity,
/// adding serialisation helpers (CSV row parsing, JSON).
class CandleModel extends Candle {
  const CandleModel({
    required super.date,
    required super.open,
    required super.high,
    required super.low,
    required super.close,
  });

  // ---------------------------------------------------------------------------
  // CSV row factory
  // ---------------------------------------------------------------------------

  /// Creates a [CandleModel] from a CSV row (list of values) and its header.
  ///
  /// Column matching is suffix-based so it works with headers like
  /// `AAPL.Open`, `AAPL.High`, etc. as well as plain `Open`, `High`.
  factory CandleModel.fromCsvRow(List<String> headers, List<dynamic> row) {
    final map = <String, String>{};
    for (var i = 0; i < headers.length && i < row.length; i++) {
      map[headers[i].trim()] = row[i].toString().trim();
    }

    String findColumn(String suffix) {
      // Exact match first, then suffix match.
      if (map.containsKey(suffix)) return map[suffix]!;
      for (final key in map.keys) {
        if (key.endsWith('.$suffix') || key.endsWith(' $suffix')) {
          return map[key]!;
        }
      }
      throw FormatException('Column ending in "$suffix" not found in $headers');
    }

    return CandleModel(
      date: findColumn('Date'),
      open: double.parse(findColumn('Open')),
      high: double.parse(findColumn('High')),
      low: double.parse(findColumn('Low')),
      close: double.parse(findColumn('Close')),
    );
  }

  // ---------------------------------------------------------------------------
  // JSON helpers
  // ---------------------------------------------------------------------------

  factory CandleModel.fromJson(Map<String, dynamic> json) {
    return CandleModel(
      date: json['date'] as String,
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
    };
  }

  // ---------------------------------------------------------------------------
  // Bulk CSV parsing
  // ---------------------------------------------------------------------------

  /// Parses a full CSV string into a list of [CandleModel].
  static List<CandleModel> fromCsvString(String csvString) {
    final rows = const CsvToListConverter().convert(csvString, eol: '\n');
    if (rows.isEmpty) return [];

    final headers = rows.first.map((e) => e.toString()).toList();
    return rows
        .skip(1)
        .where((row) => row.isNotEmpty && row.first.toString().isNotEmpty)
        .map((row) => CandleModel.fromCsvRow(headers, row))
        .toList();
  }
}
