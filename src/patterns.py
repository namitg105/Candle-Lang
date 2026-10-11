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
"""

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
    # --- Hybrid pattern kept for the report/pitch, not run through the FA ---
    "double_top": {
        "regex": None,
        "meaning": (
            "Two peaks of *similar height* separated by a trough: the up/down "
            "*shape* (U+DU+D roughly) is regular, but 'similar height' compares "
            "actual price magnitudes across candles, which needs a numeric "
            "check outside the finite automaton. Handled as: FA flags the "
            "U+DU+D shape as a *candidate*, then a small numeric post-filter "
            "checks the two peak highs are within ~1% of each other."
        ),
        "regular": False,
        "shape_regex": "U+DU+D",
    },
}
