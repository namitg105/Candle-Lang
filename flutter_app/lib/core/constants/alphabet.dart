/// The 4-letter alphabet for encoding OHLC candles.
///
/// - U = up (close > open by more than bodyThreshold)
/// - D = down (open > close by more than bodyThreshold)
/// - F = flat / doji (body smaller than bodyThreshold)
/// - G = gap (open differs from previous close by more than gapThreshold)
class Alphabet {
  Alphabet._();

  static const String up = 'U';
  static const String down = 'D';
  static const String flat = 'F';
  static const String gap = 'G';

  static const List<String> symbols = [up, down, flat, gap];

/// Thresholds for encoding classification.
  static const double bodyThreshold = 0.003; // 0.3%
  static const double gapThreshold = 0.005; // 0.5%
}
