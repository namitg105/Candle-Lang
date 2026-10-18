import 'package:equatable/equatable.dart';

/// A single pattern match annotated with its ML confidence score.
///
/// This extends the raw [MatchSpan] with the logistic regression output,
/// giving a probability estimate of how "real" the pattern occurrence is.
class ScoredMatch extends Equatable {
  /// Start index in the encoded string (inclusive).
  final int start;

  /// End index in the encoded string (exclusive).
  final int end;

  /// The matched substring from the encoded candle string.
  final String substring;

  /// ML confidence score ∈ [0, 1] from logistic regression.
  final double confidence;

  const ScoredMatch({
    required this.start,
    required this.end,
    required this.substring,
    required this.confidence,
  });

  /// Number of characters (candles) in the match.
  int get length => end - start;

  @override
  List<Object?> get props => [start, end, substring, confidence];

  @override
  String toString() =>
      'ScoredMatch($start..$end, conf=${confidence.toStringAsFixed(3)})';
}
