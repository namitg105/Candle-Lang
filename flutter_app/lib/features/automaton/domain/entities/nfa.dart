/// Non-deterministic Finite Automaton with ε-transitions.
///
/// States are integers 0..[numStates]-1.
/// Transitions map  state → { symbol → [target states] }.
/// Epsilon transitions use the key [epsilonKey].
class Nfa {
  /// Sentinel key used for ε-transitions in the transition map.
  static const String epsilonKey = 'ε';

  final int numStates;

  /// state → { symbol → [destination states] }.
  /// Symbol may be a single character or [epsilonKey].
  final Map<int, Map<String, List<int>>> transitions;

  final int start;
  final int accept;

  const Nfa({
    required this.numStates,
    required this.transitions,
    required this.start,
    required this.accept,
  });

  @override
  String toString() =>
      'NFA(states=$numStates, start=$start, accept=$accept)';
}
