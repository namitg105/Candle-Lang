import 'dfa.dart';
import 'nfa.dart';
import 'regex_node.dart';

/// Single step in DFA simulation.
class DfaStep {
  final int fromState;
  final String symbol;
  final int? toState;
  const DfaStep(this.fromState, this.symbol, this.toState);
}

/// Result of tracing a string through a DFA.
class DfaTraceResult {
  final String input;
  final bool accepted;
  final List<int> path;
  final List<DfaStep> steps;

  const DfaTraceResult({
    required this.input,
    required this.accepted,
    required this.path,
    required this.steps,
  });
}

/// Aggregated entity holding all formal automata stages.
class AutomatonInspection {
  final String regex;
  final RegexNode ast;
  final Nfa nfa;
  final Dfa dfa;
  final Dfa minDfa;

  const AutomatonInspection({
    required this.regex,
    required this.ast,
    required this.nfa,
    required this.dfa,
    required this.minDfa,
  });

  int get nfaStates => nfa.numStates;
  int get dfaStates => dfa.numStates;
  int get minDfaStates => minDfa.numStates;

  double get reductionPercentage =>
      nfaStates == 0 ? 0 : ((nfaStates - minDfaStates) / nfaStates) * 100.0;

  /// Simulates candidate string through minimized DFA.
  DfaTraceResult simulate(String input) {
    var state = minDfa.start;
    final path = <int>[state];
    final steps = <DfaStep>[];

    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      final next = minDfa.transitions[state]?[ch];
      steps.add(DfaStep(state, ch, next));
      if (next == null) {
        return DfaTraceResult(
          input: input,
          accepted: false,
          path: path,
          steps: steps,
        );
      }
      state = next;
      path.add(state);
    }

    final accepted = minDfa.accepts.contains(state);
    return DfaTraceResult(
      input: input,
      accepted: accepted,
      path: path,
      steps: steps,
    );
  }
}
