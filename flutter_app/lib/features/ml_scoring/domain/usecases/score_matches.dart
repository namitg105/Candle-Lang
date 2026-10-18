import '../../../encoding/domain/entities/candle.dart';
import '../../../pattern_detection/domain/entities/pattern_result.dart';
import '../entities/scored_match.dart';
import '../repositories/ml_repository.dart';

/// Use case: train the confidence model on every match found this run,
/// then score each one.
class ScoreMatches {
  final MlRepository repository;

  ScoreMatches(this.repository);

  Map<String, List<ScoredMatch>> call(ScoreMatchesParams params) {
    return repository.trainAndScore(
      patternResults: params.patternResults,
      encodedString: params.encodedString,
      candles: params.candles,
    );
  }
}

class ScoreMatchesParams {
  final List<PatternResult> patternResults;
  final String encodedString;
  final List<Candle> candles;

  const ScoreMatchesParams({
    required this.patternResults,
    required this.encodedString,
    required this.candles,
  });
}
