import 'package:dartz/dartz.dart';

import '../../../../core/constants/alphabet.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/dfa.dart';
import '../../domain/entities/match_span.dart';
import '../../domain/entities/nfa.dart';
import '../../domain/entities/regex_node.dart';
import '../../domain/repositories/automaton_repository.dart';

/// Implements all formal automata algorithms in pure Dart:
///
/// - Recursive-descent regex parser
/// - Thompson's Construction (regex AST → ε-NFA)
/// - Thread-based NFA substring search (leftmost-longest)
/// - Subset Construction (NFA → DFA)
/// - Moore's partition-refinement (DFA minimization)
class AutomatonRepositoryImpl implements AutomatonRepository {
  // ── Regex Parser ────────────────────────────────────────────────────

  @override
  Either<Failure, RegexNode> parseRegex(String pattern) {
    try {
      final parser = _RegexParser(pattern);
      final ast = parser.parse();
      return Right(ast);
    } catch (e) {
      return Left(ComputationFailure('Regex parse error: $e'));
    }
  }

  // ── Thompson's Construction ─────────────────────────────────────────

  @override
  Either<Failure, Nfa> buildNfa(RegexNode ast) {
    try {
      final builder = _ThompsonBuilder();
      final (start, accept) = builder.build(ast);
      // Convert internal edge-list format to Map<int, Map<String, List<int>>>
      final transitions = <int, Map<String, List<int>>>{};
      for (var i = 0; i < builder.numStates; i++) {
        transitions[i] = {};
      }
      for (final entry in builder.edges.entries) {
        final src = entry.key;
        for (final (symbol, dst) in entry.value) {
          final key = symbol ?? Nfa.epsilonKey;
          transitions[src]!.putIfAbsent(key, () => []).add(dst);
        }
      }
      return Right(Nfa(
        numStates: builder.numStates,
        transitions: transitions,
        start: start,
        accept: accept,
      ));
    } catch (e) {
      return Left(ComputationFailure("Thompson's Construction failed: $e"));
    }
  }

  // ── NFA Search ──────────────────────────────────────────────────────

  @override
  Either<Failure, List<MatchSpan>> searchNfa(Nfa nfa, String text) {
    try {
      final matches = _searchSubstrings(nfa, text);
      return Right(matches);
    } catch (e) {
      return Left(ComputationFailure('NFA search failed: $e'));
    }
  }

  // ── Subset Construction ─────────────────────────────────────────────

  @override
  Either<Failure, Dfa> buildDfa(Nfa nfa) {
    try {
      final dfa = _subsetConstruction(nfa);
      return Right(dfa);
    } catch (e) {
      return Left(ComputationFailure('Subset Construction failed: $e'));
    }
  }

  // ── DFA Minimization ────────────────────────────────────────────────

  @override
  Either<Failure, Dfa> minimizeDfa(Dfa dfa) {
    try {
      final minDfa = _minimizeDfa(dfa);
      return Right(minDfa);
    } catch (e) {
      return Left(ComputationFailure('DFA minimization failed: $e'));
    }
  }

  // ── DFA Acceptance ──────────────────────────────────────────────────

  @override
  bool dfaAccepts(Dfa dfa, String text) {
    var state = dfa.start;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      final next = dfa.transitions[state]?[ch];
      if (next == null) return false;
      state = next;
    }
    return dfa.accepts.contains(state);
  }

  // ====================================================================
  // Private algorithm implementations
  // ====================================================================

  // ── Epsilon closure helper ──────────────────────────────────────────

  static Set<int> _epsilonClosure(Nfa nfa, Set<int> states) {
    final closure = Set<int>.from(states);
    final stack = List<int>.from(states);
    while (stack.isNotEmpty) {
      final s = stack.removeLast();
      final epsTargets = nfa.transitions[s]?[Nfa.epsilonKey];
      if (epsTargets != null) {
        for (final target in epsTargets) {
          if (closure.add(target)) {
            stack.add(target);
          }
        }
      }
    }
    return closure;
  }

  // ── Move helper ─────────────────────────────────────────────────────

  static Set<int> _move(Nfa nfa, Set<int> states, String symbol) {
    final result = <int>{};
    for (final s in states) {
      final targets = nfa.transitions[s]?[symbol];
      if (targets != null) {
        result.addAll(targets);
      }
    }
    return result;
  }

  // ── Thread-based NFA substring search ───────────────────────────────
  //
  // Spawns a new "thread" (state-set) at every position in the text,
  // exactly like a grep-style Thompson NFA engine. Keeps matching
  // O(n × |Q|) instead of exponential backtracking.
  //
  // Applies leftmost-longest deduplication: for overlapping matches
  // starting at the same position, only the longest is kept.

  static List<MatchSpan> _searchSubstrings(Nfa nfa, String text) {
    final rawMatches = <MatchSpan>[];
    // threads: list of (start_index, state_set)
    var threads = <(int, Set<int>)>[];

    for (var i = 0; i <= text.length; i++) {
      // Spawn a new thread at position i
      if (i < text.length) {
        threads.add((i, _epsilonClosure(nfa, {nfa.start})));
      }

      final newThreads = <(int, Set<int>)>[];
      for (final (start, states) in threads) {
        if (states.contains(nfa.accept)) {
          rawMatches.add(MatchSpan(start: start, end: i));
        }
        if (i < text.length) {
          final nxt = _epsilonClosure(nfa, _move(nfa, states, text[i]));
          if (nxt.isNotEmpty) {
            newThreads.add((start, nxt));
          }
        }
      }
      threads = newThreads;
    }

    // Leftmost-longest deduplication
    return _deduplicateMatches(rawMatches);
  }

  /// Keep only the longest match for each starting position.
  static List<MatchSpan> _deduplicateMatches(List<MatchSpan> matches) {
    if (matches.isEmpty) return matches;

    final best = <int, MatchSpan>{};
    for (final m in matches) {
      final existing = best[m.start];
      if (existing == null || m.length > existing.length) {
        best[m.start] = m;
      }
    }

    final result = best.values.toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return result;
  }

  // ── Subset Construction (NFA → DFA) ─────────────────────────────────
  //
  // Classical powerset construction: each DFA state represents a set
  // of NFA states. We track which NFA states compose each DFA state
  // in stateLabels for debugging/visualization.

  static Dfa _subsetConstruction(Nfa nfa) {
    final alphabet = Alphabet.symbols;
    final startSet = _epsilonClosure(nfa, {nfa.start});
    final startKey = _setKey(startSet);

    final dfaStates = <String, int>{startKey: 0};
    final dfaSets = <int, Set<int>>{0: startSet};
    final unmarked = <String>[startKey];
    final transitions = <int, Map<String, int>>{0: {}};
    final labels = <int, String>{0: _labelForSet(startSet)};

    while (unmarked.isNotEmpty) {
      final currentKey = unmarked.removeLast();
      final currentId = dfaStates[currentKey]!;
      final currentSet = dfaSets[currentId]!;

      for (final symbol in alphabet) {
        final target = _epsilonClosure(nfa, _move(nfa, currentSet, symbol));
        if (target.isEmpty) continue; // implicit dead state

        final targetKey = _setKey(target);
        if (!dfaStates.containsKey(targetKey)) {
          final newId = dfaStates.length;
          dfaStates[targetKey] = newId;
          dfaSets[newId] = target;
          transitions[newId] = {};
          labels[newId] = _labelForSet(target);
          unmarked.add(targetKey);
        }
        transitions[currentId]![symbol] = dfaStates[targetKey]!;
      }
    }

    final accepts = <int>{};
    for (final entry in dfaSets.entries) {
      if (entry.value.contains(nfa.accept)) {
        accepts.add(entry.key);
      }
    }

    return Dfa(
      numStates: dfaStates.length,
      transitions: transitions,
      start: 0,
      accepts: accepts,
      stateLabels: labels,
    );
  }

  /// Canonical key for a set of NFA states (for hash-map lookup).
  static String _setKey(Set<int> states) {
    final sorted = states.toList()..sort();
    return sorted.join(',');
  }

  /// Human-readable label for a DFA state (the NFA state-set).
  static String _labelForSet(Set<int> states) {
    final sorted = states.toList()..sort();
    return '{${sorted.join(',')}}';
  }

  // ── Moore's Partition-Refinement DFA Minimization ───────────────────
  //
  // Start with two groups: accepting and non-accepting states.
  // Repeatedly split groups by the "signature" of their transitions
  // (which partition each symbol leads to) until no further splits occur.

  static Dfa _minimizeDfa(Dfa dfa) {
    final alphabet = Alphabet.symbols;
    final states = List.generate(dfa.numStates, (i) => i);
    final accepting = Set<int>.from(dfa.accepts);
    final nonAccepting = states.toSet().difference(accepting);

    var partitions = <Set<int>>[
      if (accepting.isNotEmpty) accepting,
      if (nonAccepting.isNotEmpty) nonAccepting,
    ];

    int partitionId(int state, List<Set<int>> parts) {
      for (var i = 0; i < parts.length; i++) {
        if (parts[i].contains(state)) return i;
      }
      return -1; // dead/trap state
    }

    var changed = true;
    while (changed) {
      changed = false;
      final newPartitions = <Set<int>>[];

      for (final group in partitions) {
        final buckets = <String, Set<int>>{};

        for (final s in group) {
          final sig = alphabet.map((a) {
            final target = dfa.transitions[s]?[a];
            return target == null ? -1 : partitionId(target, partitions);
          }).join(',');

          buckets.putIfAbsent(sig, () => {}).add(s);
        }

        if (buckets.length > 1) changed = true;
        newPartitions.addAll(buckets.values);
      }
      partitions = newPartitions;
    }

    // Build minimized DFA from final partitions
    final groupOf = <int, int>{};
    for (var gid = 0; gid < partitions.length; gid++) {
      for (final s in partitions[gid]) {
        groupOf[s] = gid;
      }
    }

    final newStart = groupOf[dfa.start]!;
    final newAccepts = dfa.accepts.map((s) => groupOf[s]!).toSet();
    final newTransitions = <int, Map<String, int>>{};
    final newLabels = <int, String>{};

    for (var gid = 0; gid < partitions.length; gid++) {
      final rep = partitions[gid].first;
      final repTrans = dfa.transitions[rep] ?? {};
      newTransitions[gid] = {};

      for (final a in alphabet) {
        if (repTrans.containsKey(a)) {
          newTransitions[gid]![a] = groupOf[repTrans[a]!]!;
        }
      }

      // Merge labels from all states in this partition
      final mergedLabels = partitions[gid]
          .map((s) => dfa.stateLabels?[s] ?? 'q$s')
          .join('∪');
      newLabels[gid] = mergedLabels;
    }

    return Dfa(
      numStates: partitions.length,
      transitions: newTransitions,
      start: newStart,
      accepts: newAccepts,
      stateLabels: newLabels,
    );
  }
}

// ======================================================================
// Private recursive-descent regex parser
// ======================================================================
//
// Supported syntax over alphabet {U, D, F, G}:
//   a         literal symbol
//   (r)       grouping
//   r1 r2     concatenation
//   r1|r2     union / alternation
//   r*        Kleene star (zero or more)
//   r+        one or more (sugar: r r*)
//   r?        zero or one (sugar: r|ε)
//   [abc]     character class (sugar: a|b|c)
//   r{n,}     at least n (sugar: r^n r*)
//
// Precedence: union < concat < postfix(* + ? {n,})

class _RegexParser {
  final String pattern;
  int _pos = 0;

  _RegexParser(this.pattern);

  String? _peek() => _pos < pattern.length ? pattern[_pos] : null;

  String? _advance() {
    final ch = _peek();
    _pos++;
    return ch;
  }

  RegexNode parse() {
    final node = _parseUnion();
    if (_pos != pattern.length) {
      throw FormatException(
        "Unexpected '${_peek()}' at position $_pos in /$pattern/",
      );
    }
    return node;
  }

  RegexNode _parseUnion() {
    final parts = <RegexNode>[_parseConcat()];
    while (_peek() == '|') {
      _advance();
      parts.add(_parseConcat());
    }
    return parts.length == 1 ? parts[0] : UnionNode(parts);
  }

  RegexNode _parseConcat() {
    final parts = <RegexNode>[];
    while (_peek() != null && _peek() != '|' && _peek() != ')') {
      parts.add(_parseRepeat());
    }
    if (parts.isEmpty) return EpsilonNode();
    return parts.length == 1 ? parts[0] : ConcatNode(parts);
  }

  RegexNode _parseRepeat() {
    var atom = _parseAtom();
    while (_peek() == '*' || _peek() == '+' || _peek() == '?' || _peek() == '{') {
      final op = _advance();
      if (op == '*') {
        atom = StarNode(atom);
      } else if (op == '+') {
        // r+ = r r*
        atom = ConcatNode([atom, StarNode(atom)]);
      } else if (op == '?') {
        // r? = r | ε
        atom = UnionNode([atom, EpsilonNode()]);
      } else if (op == '{') {
        // {n,} form only
        var numStr = '';
        while (_peek() != null && _peek()!.contains(RegExp(r'[0-9]'))) {
          numStr += _advance()!;
        }
        if (_peek() != ',') {
          throw FormatException('Only {n,} (at-least-n) form is supported');
        }
        _advance(); // consume ','
        if (_peek() != '}') {
          throw FormatException('Only {n,} (at-least-n) form is supported');
        }
        _advance(); // consume '}'
        final n = int.parse(numStr);
        if (n < 1) {
          throw FormatException('{n,} requires n >= 1');
        }
        // Build: atom^n followed by atom*
        final copies = <RegexNode>[
          for (var i = 0; i < n; i++) atom,
          StarNode(atom),
        ];
        atom = copies.length == 1 ? copies[0] : ConcatNode(copies);
      }
    }
    return atom;
  }

  RegexNode _parseAtom() {
    final ch = _peek();
    if (ch == null) {
      throw FormatException('Unexpected end of pattern');
    }
    if (ch == '(') {
      _advance();
      final node = _parseUnion();
      if (_peek() != ')') {
        throw FormatException("Expected closing ')'");
      }
      _advance();
      return node;
    }
    if (ch == '[') {
      _advance();
      final choices = <RegexNode>[];
      while (_peek() != ']') {
        if (_peek() == null) {
          throw FormatException("Unclosed character class '['");
        }
        choices.add(CharNode(_advance()!));
      }
      _advance(); // consume ']'
      return choices.length == 1 ? choices[0] : UnionNode(choices);
    }
    if (_isLiteral(ch)) {
      _advance();
      return CharNode(ch);
    }
    throw FormatException("Unexpected character '$ch' at position $_pos");
  }

  /// Accept any alphanumeric character as a literal.
  bool _isLiteral(String ch) => RegExp(r'[a-zA-Z0-9]').hasMatch(ch);
}
