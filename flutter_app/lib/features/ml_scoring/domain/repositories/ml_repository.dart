import '../../../encoding/domain/entities/candle.dart';
import '../../../pattern_detection/domain/entities/pattern_result.dart';
import '../entities/scored_match.dart';

/// Contract for ML scoring operations.
///
/// Trains a logistic regression model from scratch — at analysis time,
/// via gradient descent — over every match the automaton pipeline found
/// across all patterns, then scores each match with the trained model.
abstract class MlRepository {
  /// Builds the training set from [patternResults] (features per match,
  /// labels from each match's 5-day forward return aligned with its
  /// pattern's expected direction), fits a logistic regression via
  /// gradient descent, and scores every match with the fitted model.
  ///
  /// Returns a map from pattern name to that pattern's scored matches.
  Map<String, List<ScoredMatch>> trainAndScore({
    required List<PatternResult> patternResults,
    required String encodedString,
    required List<Candle> candles,
  });
}
