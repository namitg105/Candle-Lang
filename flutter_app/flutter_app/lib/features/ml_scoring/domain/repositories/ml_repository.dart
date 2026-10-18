import '../../../automaton/domain/entities/match_span.dart';
import '../../../encoding/domain/entities/candle.dart';
import '../entities/scored_match.dart';

/// Contract for ML scoring operations.
///
/// Scores raw pattern matches using a pure-Dart logistic regression
/// model with 11 hand-crafted features.
abstract class MlRepository {
  /// Scores a list of raw [MatchSpan]s using logistic regression.
  ///
  /// Each match is enriched with features computed from the surrounding
  /// candle data and assigned a confidence score ∈ [0, 1].
  List<ScoredMatch> scoreMatches({
    required List<MatchSpan> matches,
    required String encodedString,
    required List<Candle> candles,
    required String patternName,
  });
}
