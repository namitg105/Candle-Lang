import '../../../encoding/domain/entities/candle.dart';
import '../../../pattern_detection/domain/entities/pattern_definition.dart';

/// Full result of the analysis pipeline, ready for display.
class AnalysisResult {
  final String symbol;
  final String dateRange;
  final int numCandles;
  final String encodedString;
  final List<Candle> candles;
  final List<PatternResultWithScores> patterns;

  const AnalysisResult({
    required this.symbol,
    required this.dateRange,
    required this.numCandles,
    required this.encodedString,
    required this.candles,
    required this.patterns,
  });
}

/// A single pattern's detection results, including ML confidence scores.
class PatternResultWithScores {
  final PatternDefinition definition;
  final List<ScoredMatchResult> matches;
  final int nfaStates;
  final int dfaStates;
  final int minDfaStates;
  final bool crossCheckPassed;

  const PatternResultWithScores({
    required this.definition,
    required this.matches,
    required this.nfaStates,
    required this.dfaStates,
    required this.minDfaStates,
    required this.crossCheckPassed,
  });

  /// Average ML confidence across all matches, or 0 if none.
  double get averageConfidence {
    if (matches.isEmpty) return 0.0;
    final sum = matches.fold<double>(0.0, (s, m) => s + m.confidence);
    return sum / matches.length;
  }

  bool get isBullish => definition.direction == PatternDirection.bullish;

  /// Human-readable display name derived from the pattern key.
  String get displayName {
    return definition.name
        .split('_')
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

/// One matched span with its ML confidence score.
class ScoredMatchResult {
  final int start;
  final int end;
  final String substring;
  final double confidence;

  const ScoredMatchResult({
    required this.start,
    required this.end,
    required this.substring,
    required this.confidence,
  });
}
