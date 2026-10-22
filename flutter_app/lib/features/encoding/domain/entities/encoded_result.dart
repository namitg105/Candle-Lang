import 'package:equatable/equatable.dart';

import 'candle.dart';

/// Per-candle encoding breakdown — shows why each candle got its symbol.
class EncodingTrace extends Equatable {
  final String date;
  final String symbol;
  final double gapPercent;
  final double bodyPercent;

  const EncodingTrace({
    required this.date,
    required this.symbol,
    required this.gapPercent,
    required this.bodyPercent,
  });

  @override
  List<Object?> get props => [date, symbol, gapPercent, bodyPercent];
}

/// The result of encoding a list of candles into a formal-language string.
class EncodedResult extends Equatable {
  /// The encoded string over {U, D, F, G}.
  final String encoded;

  /// Per-candle encoding trace for inspection / debugging.
  final List<EncodingTrace> trace;

  /// The original candle list, aligned index-by-index with [trace].
  final List<Candle> candles;

  /// The calibrated body-size cutoff used to decide flat (F) vs. a real
  /// U/D move for every candle in [trace] -- see
  /// `EncodingRepositoryImpl.encodeCandles` for how it's calibrated from
  /// this exact candle set's own average move.
  final double bodyThreshold;

  /// The calibrated open-vs-previous-close cutoff used to decide whether
  /// a candle counts as a gap (G).
  final double gapThreshold;

  const EncodedResult({
    required this.encoded,
    required this.trace,
    required this.candles,
    this.bodyThreshold = 0,
    this.gapThreshold = 0,
  });

  @override
  List<Object?> get props =>
      [encoded, trace, candles, bodyThreshold, gapThreshold];
}
