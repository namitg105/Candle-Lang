"""
nfa.py
------
Core epsilon-NFA data structure, plus:
  - Thompson's Construction: build an NFA directly from a regex AST
    (regex_ast.Node), following the classical inductive rules.
  - epsilon-closure and a substring-search simulation, so we can find
    every position in a candle string where a pattern occurs.

This is the heart of Module 1 (regular expressions -> NFA) from the
syllabus, implemented without using Python's `re` engine at any point.
"""

from dataclasses import dataclass, field
from typing import Dict, FrozenSet, List, Set, Tuple

from regex_ast import Char, Concat, Epsilon, Node, Star, Union

EPS = None  # epsilon transitions are keyed by None in the transition table


@dataclass
class NFA:
    """
    States are plain integers 0..num_states-1.
    transitions[state] is a list of (symbol_or_None, target_state).
    symbol_or_None == None means an epsilon-transition.
    """
    num_states: int
    transitions: Dict[int, List[Tuple[str, int]]]
    start: int
    accept: int

    def add_state(self) -> int:
        sid = self.num_states
        self.num_states += 1
        self.transitions[sid] = []
        return sid

    def add_edge(self, src: int, symbol, dst: int):
        self.transitions[src].append((symbol, dst))


class ThompsonBuilder:
    """Builds an NFA fragment-by-fragment using Thompson's Construction."""

    def __init__(self):
        self.num_states = 0
        self.transitions: Dict[int, List[Tuple[str, int]]] = {}

    def new_state(self) -> int:
        sid = self.num_states
        self.num_states += 1
        self.transitions[sid] = []
        return sid

    def add_edge(self, src: int, symbol, dst: int):
        self.transitions[src].append((symbol, dst))

    def build(self, node: Node) -> Tuple[int, int]:
        """Returns (start_state, accept_state) for the fragment representing `node`."""
        if isinstance(node, Char):
            s, a = self.new_state(), self.new_state()
            self.add_edge(s, node.value, a)
            return s, a

        if isinstance(node, Epsilon):
            s, a = self.new_state(), self.new_state()
            self.add_edge(s, EPS, a)
            return s, a

        if isinstance(node, Concat):
            starts_ends = [self.build(p) for p in node.parts]
            for (_, a1), (s2, _) in zip(starts_ends, starts_ends[1:]):
                self.add_edge(a1, EPS, s2)
            return starts_ends[0][0], starts_ends[-1][1]

        if isinstance(node, Union):
            s, a = self.new_state(), self.new_state()
            for part in node.parts:
                ps, pa = self.build(part)
                self.add_edge(s, EPS, ps)
                self.add_edge(pa, EPS, a)
            return s, a

        if isinstance(node, Star):
            s, a = self.new_state(), self.new_state()
            ps, pa = self.build(node.inner)
            self.add_edge(s, EPS, ps)
            self.add_edge(s, EPS, a)
            self.add_edge(pa, EPS, ps)
            self.add_edge(pa, EPS, a)
            return s, a

        raise TypeError(f"Unknown AST node type: {type(node)}")


def thompson_construct(node: Node) -> NFA:
    """Public entry point: regex AST -> NFA via Thompson's Construction."""
    builder = ThompsonBuilder()
    start, accept = builder.build(node)
    return NFA(builder.num_states, builder.transitions, start, accept)


def regex_to_nfa(pattern: str) -> NFA:
    from regex_ast import parse_regex
    ast = parse_regex(pattern)
    return thompson_construct(ast)


# ---- Simulation ---------------------------------------------------------

def epsilon_closure(nfa: NFA, states: Set[int]) -> FrozenSet[int]:
    stack = list(states)
    closure = set(states)
    while stack:
        s = stack.pop()
        for symbol, target in nfa.transitions.get(s, []):
            if symbol is EPS and target not in closure:
                closure.add(target)
                stack.append(target)
    return frozenset(closure)


def move(nfa: NFA, states: Set[int], symbol: str) -> FrozenSet[int]:
    result = set()
    for s in states:
        for sym, target in nfa.transitions.get(s, []):
            if sym == symbol:
                result.add(target)
    return frozenset(result)


def full_match(nfa: NFA, text: str) -> bool:
    """Does the NFA accept `text` in its entirety?"""
    current = epsilon_closure(nfa, {nfa.start})
    for ch in text:
        current = epsilon_closure(nfa, move(nfa, current, ch))
        if not current:
            return False
    return nfa.accept in current


def search_substrings(nfa: NFA, text: str):
    """
    Find every (start, end) span in `text` (end exclusive) where the
    pattern recognized by `nfa` occurs, using multi-threaded NFA
    simulation (a new thread is spawned at every position, exactly the
    textbook technique used by grep-style regex engines built on
    Thompson's construction -- this keeps matching O(n * |Q|) instead of
    the exponential blowup of backtracking engines).
    """
    matches = []
    # threads: list of (start_index, frozenset_of_states)
    threads: List[Tuple[int, FrozenSet[int]]] = []

    for i in range(len(text) + 1):
        # start a new thread at position i (i < len(text) covers all starts)
        if i < len(text):
            threads.append((i, epsilon_closure(nfa, {nfa.start})))

        new_threads = []
        for start, states in threads:
            if nfa.accept in states:
                matches.append((start, i))
            if i < len(text):
                nxt = epsilon_closure(nfa, move(nfa, states, text[i]))
                if nxt:
                    new_threads.append((start, nxt))
        threads = new_threads

    return matches
