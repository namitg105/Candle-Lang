/// Deterministic Finite Automaton.
///
/// States are integers 0..[numStates]-1.
/// Transitions map  state → { symbol → single target state }.
class Dfa {
  final int numStates;

  /// state → { symbol → destination state }.
  final Map<int, Map<String, int>> transitions;

  final int start;
  final Set<int> accepts;

  /// Optional labels for debugging / visualization.
  /// Maps DFA state id → human-readable label (e.g. the NFA state-set).
  final Map<int, String>? stateLabels;

  const Dfa({
    required this.numStates,
    required this.transitions,
    required this.start,
    required this.accepts,
    this.stateLabels,
  });

  @override
  String toString() =>
      'DFA(states=$numStates, start=$start, accepts=$accepts)';
}
