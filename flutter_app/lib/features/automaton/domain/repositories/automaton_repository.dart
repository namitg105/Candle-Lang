import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dfa.dart';
import '../entities/match_span.dart';
import '../entities/nfa.dart';
import '../entities/regex_node.dart';

/// Contract for all automaton-theory operations.
///
/// Domain layer defines what, Data layer implements how.
abstract class AutomatonRepository {
  /// Parse a regex pattern string into an AST.
  Either<Failure, RegexNode> parseRegex(String pattern);

  /// Thompson's Construction: regex AST → ε-NFA.
  Either<Failure, Nfa> buildNfa(RegexNode ast);

  /// Thread-based NFA substring search (leftmost-longest dedup).
  Either<Failure, List<MatchSpan>> searchNfa(Nfa nfa, String text);

  /// Subset Construction: NFA → DFA.
  Either<Failure, Dfa> buildDfa(Nfa nfa);

  /// Moore's partition-refinement DFA minimization.
  Either<Failure, Dfa> minimizeDfa(Dfa dfa);

  /// Check if a DFA accepts the given string.
  bool dfaAccepts(Dfa dfa, String text);
}
