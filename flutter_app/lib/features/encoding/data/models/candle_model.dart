import 'package:csv/csv.dart';

import '../../../../core/error/exceptions.dart';
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

    // double.parse throws a FormatException (not a bare TypeError) on a
    // blank/garbled cell, and names exactly which column was bad --
    // instead of letting a malformed row crash the whole screen with an
    // opaque "type 'Null' is not a subtype of type 'double'".
    double parseColumn(String suffix) {
      final raw = findColumn(suffix);
      final parsed = double.tryParse(raw);
      if (parsed == null) {
        throw CacheException(
          'Bundled CSV has an invalid "$suffix" value: "$raw"',
        );
      }
      return parsed;
    }

    return CandleModel(
      date: findColumn('Date'),
      open: parseColumn('Open'),
      high: parseColumn('High'),
      low: parseColumn('Low'),
      close: parseColumn('Close'),
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

  /// Parses one candle from Twelve Data's `time_series` JSON response.
  /// Twelve Data sends price values as strings, so this model converts them
  /// into Dart doubles before the domain layer uses them.
  factory CandleModel.fromTwelveDataJson(Map<String, dynamic> json) {
    double number(String key) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
      // Turns a bare, unlocatable TypeError ("type 'Null' is not a
      // subtype of type 'double'") into a ServerException carrying the
      // exact field and the exact value the backend actually sent --
      // this flows through the same error path as any other API error
      // (see candle_remote_data_source.dart), so the UI shows a clear
      // "data is currently not available" message instead of crashing.
      throw ServerException(
        'Live market API sent an unexpected value for "$key": $value',
      );
    }

    return CandleModel(
      date: json['datetime'] as String,
      open: number('open'),
      high: number('high'),
      low: number('low'),
      close: number('close'),
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
