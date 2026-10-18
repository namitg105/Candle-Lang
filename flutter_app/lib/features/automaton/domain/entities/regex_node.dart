/// AST node hierarchy for regular expressions over the candle alphabet.
///
/// Produced by the recursive-descent regex parser and consumed by
/// Thompson's Construction to build an NFA.
sealed class RegexNode {}

/// Matches a single literal character (e.g. 'U', 'D', 'F', 'G').
class CharNode extends RegexNode {
  final String value;
  CharNode(this.value);

  @override
  String toString() => 'Char($value)';
}

/// Matches the empty string — used internally for `?` and `|`.
class EpsilonNode extends RegexNode {
  @override
  String toString() => 'Epsilon';
}

/// Matches a sequence of sub-expressions in order.
class ConcatNode extends RegexNode {
  final List<RegexNode> parts;
  ConcatNode(this.parts);

  @override
  String toString() => 'Concat(${parts.join(', ')})';
}

/// Matches any one of the alternatives (the `|` operator).
class UnionNode extends RegexNode {
  final List<RegexNode> parts;
  UnionNode(this.parts);

  @override
  String toString() => 'Union(${parts.join(', ')})';
}

/// Kleene star — matches zero or more repetitions of [inner].
class StarNode extends RegexNode {
  final RegexNode inner;
  StarNode(this.inner);

  @override
  String toString() => 'Star($inner)';
}
