import 'package:equatable/equatable.dart';

import '../../../automaton/domain/entities/match_span.dart';
import 'pattern_definition.dart';

/// Result of running one pattern through the automaton pipeline.
class PatternResult extends Equatable {
  final PatternDefinition definition;
  final List<MatchSpan> matches;
  final int nfaStates;
  final int dfaStates;
  final int minDfaStates;
  final bool crossCheckPassed;

  const PatternResult({
    required this.definition,
    required this.matches,
    required this.nfaStates,
    required this.dfaStates,
    required this.minDfaStates,
    required this.crossCheckPassed,
  });

  int get matchCount => matches.length;

  @override
  List<Object?> get props => [
        definition,
        matches,
        nfaStates,
        dfaStates,
        minDfaStates,
        crossCheckPassed,
      ];
}
