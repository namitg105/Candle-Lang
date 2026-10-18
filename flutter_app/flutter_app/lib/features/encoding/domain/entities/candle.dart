import 'package:equatable/equatable.dart';

/// A single OHLC candlestick data point.
class Candle extends Equatable {
  final String date;
  final double open;
  final double high;
  final double low;
  final double close;

  const Candle({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  /// Whether the candle closed higher than it opened.
  bool get isBullish => close >= open;

  @override
  List<Object?> get props => [date, open, high, low, close];
}
