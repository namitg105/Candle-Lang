/// The 4-letter alphabet for encoding OHLC candles.
///
/// - U = up (close > open by more than the calibrated body cutoff)
/// - D = down (open > close by more than the calibrated body cutoff)
/// - F = flat / doji (body smaller than the calibrated body cutoff)
/// - G = gap (open differs from previous close by more than the
///       calibrated gap cutoff)
///
/// The actual cutoffs are NOT fixed percentages. A fixed percentage only
/// makes sense for one timeframe: a value tuned for daily candles (where a
/// 0.3% move is tiny) would classify almost every 1-minute candle as flat,
/// since minute-to-minute moves are naturally much smaller than that. The
/// reverse problem would happen if a minute-tuned value were applied to
/// daily candles. Instead, [bodyThresholdFactor] and [gapThresholdFactor]
/// are multipliers applied to THIS candle set's own average move (see
/// `EncodingRepositoryImpl.encodeCandles`) -- so classification stays
/// meaningful whether the candles are 1-minute, daily, or anything else.
class Alphabet {
  Alphabet._();

  static const String up = 'U';
  static const String down = 'D';
  static const String flat = 'F';
  static const String gap = 'G';

  static const List<String> symbols = [up, down, flat, gap];

  /// A candle's body is "flat" when it's below this fraction of the
  /// candle set's own average body move.
  static const double bodyThresholdFactor = 0.5;

  /// An open-vs-previous-close gap counts as a real gap only once it
  /// clearly exceeds the candle set's own average gap move.
  static const double gapThresholdFactor = 1.5;
}
