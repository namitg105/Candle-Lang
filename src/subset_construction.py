"""
subset_construction.py
-----------------------
Module 2 of the syllabus: converting the epsilon-NFA produced by
Thompson's Construction into an equivalent DFA (subset / powerset
construction), then minimizing that DFA with the classic partition
-refinement (Moore's) algorithm.

Together with nfa.py this gives the full pipeline:

    regex  --(Thompson's Construction)-->  NFA
    NFA    --(Subset Construction)-------->  DFA
    DFA    --(Minimization)---------------->  minimal DFA

and lets the report show, side by side, that the NFA and its derived
(minimal) DFA accept exactly the same language -- the central theorem
of Module 2.
"""

from dataclasses import dataclass, field
from typing import Dict, FrozenSet, List, Set, Tuple

from nfa import NFA, epsilon_closure, move


ALPHABET = ("U", "D", "F", "G")


@dataclass
class DFA:
    num_states: int
    transitions: Dict[int, Dict[str, int]]   # state -> symbol -> state
    start: int
    accepts: Set[int]
    # for traceability back to the NFA (useful when drawing/explaining):
    state_labels: Dict[int, FrozenSet[int]] = field(default_factory=dict)

    def accepts_string(self, text: str) -> bool:
        state = self.start
        for ch in text:
            nxt = self.transitions.get(state, {}).get(ch)
            if nxt is None:
                return False
            state = nxt
        return state in self.accepts


def subset_construction(nfa: NFA, alphabet=ALPHABET) -> DFA:
    start_set = epsilon_closure(nfa, {nfa.start})

    dfa_states: Dict[FrozenSet[int], int] = {start_set: 0}
    unmarked = [start_set]
    transitions: Dict[int, Dict[str, int]] = {0: {}}
    labels: Dict[int, FrozenSet[int]] = {0: start_set}

    while unmarked:
        current = unmarked.pop()
        current_id = dfa_states[current]
        for symbol in alphabet:
            target = epsilon_closure(nfa, move(nfa, current, symbol))
            if not target:
                continue  # implicit dead/trap state; omitted for clarity
            if target not in dfa_states:
                new_id = len(dfa_states)
                dfa_states[target] = new_id
                labels[new_id] = target
                transitions[new_id] = {}
                unmarked.append(target)
            transitions[current_id][symbol] = dfa_states[target]

    accepts = {sid for state_set, sid in dfa_states.items() if nfa.accept in state_set}

    return DFA(
        num_states=len(dfa_states),
        transitions=transitions,
        start=0,
        accepts=accepts,
        state_labels=labels,
    )


def minimize_dfa(dfa: DFA, alphabet=ALPHABET) -> DFA:
    """
    Partition-refinement (Moore's algorithm) DFA minimization.
    Unreachable-state removal is implicit because subset_construction
    only ever builds reachable states.
    """
    states = list(range(dfa.num_states))
    accepting = set(dfa.accepts)
    non_accepting = set(states) - accepting

    partitions: List[Set[int]] = [p for p in (accepting, non_accepting) if p]

    def partition_id(state, parts):
        for i, p in enumerate(parts):
            if state in p:
                return i
        return -1

    changed = True
    while changed:
        changed = False
        new_partitions: List[Set[int]] = []
        for group in partitions:
            # split `group` by the signature (which partition each symbol's
            # transition lands in)
            buckets: Dict[Tuple, Set[int]] = {}
            for s in group:
                sig = tuple(
                    partition_id(dfa.transitions.get(s, {}).get(a), partitions)
                    for a in alphabet
                )
                buckets.setdefault(sig, set()).add(s)
            if len(buckets) > 1:
                changed = True
            new_partitions.extend(buckets.values())
        partitions = new_partitions

    # Build the minimized DFA from the final partitions
    group_of: Dict[int, int] = {}
    for gid, group in enumerate(partitions):
        for s in group:
            group_of[s] = gid

    new_start = group_of[dfa.start]
    new_accepts = {group_of[s] for s in dfa.accepts}
    new_transitions: Dict[int, Dict[str, int]] = {}
    new_labels: Dict[int, FrozenSet[int]] = {}

    for gid, group in enumerate(partitions):
        rep = next(iter(group))
        new_transitions[gid] = {
            a: group_of[dfa.transitions[rep][a]]
            for a in alphabet
            if a in dfa.transitions.get(rep, {})
        }
        merged_nfa_states = frozenset().union(*(dfa.state_labels.get(s, frozenset()) for s in group))
        new_labels[gid] = merged_nfa_states

    return DFA(
        num_states=len(partitions),
        transitions=new_transitions,
        start=new_start,
        accepts=new_accepts,
        state_labels=new_labels,
    )
