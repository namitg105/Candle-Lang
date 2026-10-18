import 'dart:math' as math;

import '../../../automaton/domain/entities/dfa.dart';
import '../../../automaton/domain/entities/match_span.dart';
import '../../../automaton/domain/repositories/automaton_repository.dart';
import '../../domain/entities/pattern_definition.dart';
import '../../domain/entities/pattern_result.dart';
import '../../domain/repositories/pattern_repository.dart';
import '../datasources/pattern_definitions_source.dart';

/// Concrete implementation of [PatternRepository].
///
/// Delegates automaton operations (parse, NFA build, DFA build, minimise)
/// to [AutomatonRepository] — respecting Clean Architecture's dependency rule.
class PatternRepositoryImpl implements PatternRepository {
  final AutomatonRepository automatonRepository;

  PatternRepositoryImpl({required this.automatonRepository});

  // ---------------------------------------------------------------------------
  // Pattern definitions
  // ---------------------------------------------------------------------------

  @override
  List<PatternDefinition> getPatternDefinitions() {
    return PatternDefinitionsSource.definitions;
  }

  // ---------------------------------------------------------------------------
  // Full pipeline: detect all patterns
  // ---------------------------------------------------------------------------

  @override
  Future<List<PatternResult>> detectAllPatterns({
    required String encodedString,
    required List<double> highs,
  }) async {
    final results = <PatternResult>[];

    for (final definition in PatternDefinitionsSource.definitions) {
      final regex = definition.regex;
      if (regex == null) continue;

      // Step 1: Parse regex → AST
      final astResult = automatonRepository.parseRegex(regex);
      final ast = astResult.fold(
        (failure) => throw Exception('Parse failed for ${definition.name}: '
            '${failure.message}'),
        (ast) => ast,
      );

      // Step 2: AST → NFA (Thompson's Construction)
      final nfaResult = automatonRepository.buildNfa(ast);
      final nfa = nfaResult.fold(
        (failure) => throw Exception('NFA build failed: ${failure.message}'),
        (nfa) => nfa,
      );

      // Step 3: NFA substring search
      final searchResult =
          automatonRepository.searchNfa(nfa, encodedString);
      var matches = searchResult.fold(
        (failure) => <MatchSpan>[],
        (matches) => matches,
      );

      // Step 4: NFA → DFA (Subset Construction)
      final dfaResult = automatonRepository.buildDfa(nfa);
      final dfa = dfaResult.fold(
        (failure) => throw Exception('DFA build failed: ${failure.message}'),
        (dfa) => dfa,
      );

      // Step 5: DFA → Minimal DFA (Moore's partition-refinement)
      final minDfaResult = automatonRepository.minimizeDfa(dfa);
      final minDfa = minDfaResult.fold(
        (failure) =>
            throw Exception('DFA minimization failed: ${failure.message}'),
        (dfa) => dfa,
      );

      // Step 6: Cross-check — every match the NFA found must also be
      // accepted by the *minimized* DFA. This is the actual equivalence
      // claim the project makes (NFA ≡ DFA ≡ minimized DFA), so it has
      // to run against minDfa, not the intermediate, unminimized dfa.
      final crossCheckPassed = _crossCheckAcceptance(
        minDfa: minDfa,
        matches: matches,
        encodedString: encodedString,
      );

      // Step 7: For the hybrid double_top, apply numeric post-check
      if (definition.isHybrid && definition.name == 'double_top') {
        matches = _filterDoubleTopMatches(
          matches: matches,
          highs: highs,
          encodedString: encodedString,
          tolerance: 0.015,
        );
      }

      results.add(PatternResult(
        definition: definition,
        matches: matches,
        nfaStates: nfa.numStates,
        dfaStates: dfa.numStates,
        minDfaStates: minDfa.numStates,
        crossCheckPassed: crossCheckPassed,
      ));
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // Double Top hybrid detection
  // ---------------------------------------------------------------------------

  @override
  List<MatchSpan> detectDoubleTop({
    required String encodedString,
    required List<double> highs,
    double tolerance = 0.015,
  }) {
    // Step 1: Regex pre-filter with U+DU+D
    const regex = 'U+DU+D';
    final astResult = automatonRepository.parseRegex(regex);
    final ast = astResult.fold(
      (f) => throw Exception('Parse failed: ${f.message}'),
      (ast) => ast,
    );

    final nfaResult = automatonRepository.buildNfa(ast);
    final nfa = nfaResult.fold(
      (f) => throw Exception('NFA build failed: ${f.message}'),
      (nfa) => nfa,
    );

    final searchResult = automatonRepository.searchNfa(nfa, encodedString);
    final rawMatches = searchResult.fold(
      (f) => <MatchSpan>[],
      (matches) => matches,
    );

    // Step 2: Numeric post-check
    return _filterDoubleTopMatches(
      matches: rawMatches,
      highs: highs,
      encodedString: encodedString,
      tolerance: tolerance,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Filters double top matches by comparing the two peak heights.
  ///
  /// For each U+DU+D match, uses the encoded string to find the boundary
  /// between the first U-run and the second U-run, then compares the
  /// max high of each run. Passes if |peak1 - peak2| / max(peak1, peak2)
  /// ≤ [tolerance].
  List<MatchSpan> _filterDoubleTopMatches({
    required List<MatchSpan> matches,
    required List<double> highs,
    required String encodedString,
    required double tolerance,
  }) {
    final filtered = <MatchSpan>[];

    for (final span in matches) {
      if (span.end > highs.length || span.end > encodedString.length) continue;

      // Walk the matched substring to find first and second U-runs.
      // Pattern structure: U+  D  U+  D
      //                    ^run1  ^run2
      double peak1 = double.negativeInfinity;
      double peak2 = double.negativeInfinity;
      bool inSecondURun = false;
      bool passedFirstD = false;

      for (var i = span.start; i < span.end && i < highs.length; i++) {
        final ch = encodedString[i];
        if (!passedFirstD) {
          // Still in the first U-run or hitting the first D.
          if (ch == 'U') {
            peak1 = math.max(peak1, highs[i]);
          } else if (ch == 'D') {
            passedFirstD = true;
          }
        } else if (!inSecondURun) {
          // After first D — looking for second U-run.
          if (ch == 'U') {
            inSecondURun = true;
            peak2 = math.max(peak2, highs[i]);
          }
        } else {
          // In the second U-run (or trailing D).
          if (ch == 'U') {
            peak2 = math.max(peak2, highs[i]);
          }
          // Trailing D ends the match — nothing to track.
        }
      }

      if (peak1 == double.negativeInfinity ||
          peak2 == double.negativeInfinity) {
        continue;
      }

      final maxPeak = math.max(peak1, peak2);
      if (maxPeak == 0) continue;

      final diff = (peak1 - peak2).abs() / maxPeak;
      if (diff <= tolerance) {
        filtered.add(span);
      }
    }

    return filtered;
  }

  /// Cross-checks that every NFA-found match is also accepted by the
  /// minimized DFA — concrete evidence that minimization preserved the
  /// language the NFA recognises.
  bool _crossCheckAcceptance({
    required Dfa minDfa,
    required List<MatchSpan> matches,
    required String encodedString,
  }) {
    for (final span in matches) {
      final substr = encodedString.substring(span.start, span.end);
      final accepted = automatonRepository.dfaAccepts(minDfa, substr);
      if (!accepted) return false;
    }
    return true;
  }
}
