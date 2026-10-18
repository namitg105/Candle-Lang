import '../../../automaton/domain/entities/match_span.dart';
import '../../../encoding/domain/entities/candle.dart';
import '../entities/scored_match.dart';
import '../repositories/ml_repository.dart';

/// Use case: score a list of pattern matches using the ML pipeline.
class ScoreMatches {
  final MlRepository repository;

  ScoreMatches(this.repository);

  List<ScoredMatch> call(ScoreMatchesParams params) {
    return repository.scoreMatches(
      matches: params.matches,
      encodedString: params.encodedString,
      candles: params.candles,
      patternName: params.patternName,
    );
  }
}

class ScoreMatchesParams {
  final List<MatchSpan> matches;
  final String encodedString;
  final List<Candle> candles;
  final String patternName;

  const ScoreMatchesParams({
    required this.matches,
    required this.encodedString,
    required this.candles,
    required this.patternName,
  });
}
