"""
patterns.py
-----------
Real candlestick trading patterns, expressed as regular expressions over
the alphabet SIGMA = {U, D, F, G}.

Being explicit about what a "regular" version of a candlestick pattern
can and cannot capture is itself part of the TOC argument: patterns that
only depend on the *sequence* of up/down/flat/gap moves are regular
languages and fit this pipeline exactly; patterns that require comparing
*magnitudes* between two candles (e.g. "the second candle's high must
match the first candle's high almost exactly" in a textbook Double Top)
are NOT expressible in a regular language over this alphabet -- that
needs context-sensitive numeric comparison, which is why those are
flagged below as "hybrid" patterns handled partly by the automaton and
partly by a numeric post-check in the ML/analysis layer.

The find_double_top_matches() function below implements this two-stage
approach: the regex U+DU+D is run through the NFA/DFA engine to find
candidate shapes, and then a numeric post-check verifies that the two
peak highs are within PEAK_TOLERANCE of each other.  This is a concrete,
constructive demonstration of the *boundary* of what a regular language
can express -- not just a citation of the pumping lemma.
"""

from __future__ import annotations
from typing import List, Sequence, Tuple

PEAK_TOLERANCE = 0.015  # 1.5% -- the two double-top peaks must be this close

PATTERNS = {
    "three_white_soldiers": {
        "regex": "U{3,}",
        "meaning": "Three or more consecutive up-candles: strong bullish continuation.",
        "regular": True,
    },
    "three_black_crows": {
        "regex": "D{3,}",
        "meaning": "Three or more consecutive down-candles: strong bearish continuation.",
        "regular": True,
    },
    "bullish_reversal": {
        "regex": "D+FU+",
        "meaning": "A downtrend, a pause/indecision candle, then upside resumes: classic reversal shape.",
        "regular": True,
    },
    "bearish_reversal": {
        "regex": "U+FD+",
        "meaning": "An uptrend, a pause/indecision candle, then downside resumes.",
        "regular": True,
    },
    "gap_and_go": {
        "regex": "GU+",
        "meaning": "A gap open immediately followed by sustained upside: momentum breakout.",
        "regular": True,
    },
    "exhaustion_gap": {
        "regex": "U{2,}GD",
        "meaning": "A run-up, a gap (often up), then an immediate reversal down: classic exhaustion signal.",
        "regular": True,
    },
    "indecision_cluster": {
        "regex": "F{2,}",
        "meaning": "Two or more flat/doji-like candles in a row: the market is undecided, often precedes a breakout.",
        "regular": True,
    },
    # --- Hybrid pattern: regex pre-filter + numeric post-check ----------
    "double_top": {
        "regex": None,
        "meaning": (
            "Two peaks of *similar height* separated by a trough: the up/down "
            "*shape* (U+DU+D roughly) is regular, but 'similar height' compares "
            "actual price magnitudes across candles, which needs a numeric "
            "check outside the finite automaton. Handled as: FA flags the "
            "U+DU+D shape as a *candidate*, then a small numeric post-filter "
            "checks the two peak highs are within ~1.5% of each other."
        ),
        "regular": False,
        "shape_regex": "U+DU+D",
    },
}

DOUBLE_TOP_REGEX = "U+DU+D"
DOUBLE_TOP_NAME = "double_top"


def dedupe_leftmost_longest(matches):
    """Collapse overlapping matches to the classic leftmost-longest,
    non-overlapping set (like a real regex `search` sweep)."""
    matches = sorted(matches, key=lambda m: (m[0], -(m[1] - m[0])))
    result = []
    next_allowed = 0
    for start, end in matches:
        if start >= next_allowed and end > start:
            result.append((start, end))
            next_allowed = end
    return result


def find_double_top_matches(
    encoded: str,
    highs: Sequence[float],
    tolerance: float = PEAK_TOLERANCE,
) -> List[Tuple[int, int]]:
    """
    Run the regular pre-filter (U+DU+D) through the NFA engine to find
    candidate shapes, then apply the numeric peak-height post-check.

    `highs` must be the list of daily high prices aligned 1:1 with the
    candle sequence used to produce `encoded`.  Because encode_candles()
    includes the first candle (unlike some other encoders that skip it),
    highs[i] corresponds directly to the candle that produced encoded[i].

    Returns only the matches that pass BOTH the regex shape check and
    the numeric peak-equality check.
    """
    from nfa import regex_to_nfa, search_substrings

    nfa = regex_to_nfa(DOUBLE_TOP_REGEX)
    raw_matches = search_substrings(nfa, encoded)
    shape_matches = dedupe_leftmost_longest(raw_matches)

    confirmed: List[Tuple[int, int]] = []
    for start, end in shape_matches:
        segment = encoded[start:end]

        # locate the two U-runs inside this match: U+ D U+ D
        first_u_len = 0
        while first_u_len < len(segment) and segment[first_u_len] == "U":
            first_u_len += 1

        if first_u_len == 0 or first_u_len >= len(segment):
            continue

        # first peak = highest high during the first U-run
        first_run_highs = [
            highs[start + i] for i in range(first_u_len)
            if start + i < len(highs)
        ]

        # after the first D, the second U-run starts
        rest = segment[first_u_len + 1:]  # skip the D
        second_u_len = 0
        while second_u_len < len(rest) and rest[second_u_len] == "U":
            second_u_len += 1

        if second_u_len == 0:
            continue

        second_run_start = start + first_u_len + 1
        second_run_highs = [
            highs[second_run_start + i] for i in range(second_u_len)
            if second_run_start + i < len(highs)
        ]

        if not first_run_highs or not second_run_highs:
            continue

        peak1 = max(first_run_highs)
        peak2 = max(second_run_highs)

        if peak1 > 0 and abs(peak1 - peak2) / peak1 <= tolerance:
            confirmed.append((start, end))

    return confirmed
