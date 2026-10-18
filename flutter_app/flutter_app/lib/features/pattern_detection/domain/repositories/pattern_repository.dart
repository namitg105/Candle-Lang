import '../../../automaton/domain/entities/match_span.dart';
import '../entities/pattern_definition.dart';
import '../entities/pattern_result.dart';

/// Contract for pattern detection operations.
abstract class PatternRepository {
  /// Returns the hardcoded list of all 8 pattern definitions.
  List<PatternDefinition> getPatternDefinitions();

  /// Runs every pattern through the NFA/DFA pipeline and returns results.
  Future<List<PatternResult>> detectAllPatterns({
    required String encodedString,
    required List<double> highs,
  });

  /// Detects the Double Top hybrid pattern:
  /// regex pre-filter (U+DU+D shape) + numeric peak-height post-check.
  List<MatchSpan> detectDoubleTop({
    required String encodedString,
    required List<double> highs,
    double tolerance = 0.015,
  });
}
