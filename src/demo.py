"""
demo.py
-------
End-to-end demo of the CandleLang pipeline built so far:

    synthetic OHLC data
        -> candle_encoder.encode_candles()      [data representation]
        -> patterns.PATTERNS[...]['regex']      [pattern definitions]
        -> nfa.regex_to_nfa()                   [Thompson's Construction]
        -> nfa.search_substrings()              [NFA-based substring search]
        -> subset_construction.subset_construction() + minimize_dfa()
        -> DFA.accepts_string() used to *independently verify* every
           match the NFA found (NFA/DFA equivalence, made concrete)
        -> visualize.draw_nfa()/draw_dfa()       [state diagrams for the report]

Run with:  python3 demo.py
"""

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from candle_encoder import encode_candles
from synthetic_data import generate_synthetic_candles
from patterns import PATTERNS
from nfa import regex_to_nfa, search_substrings
from subset_construction import subset_construction, minimize_dfa
from visualize import draw_nfa, draw_dfa

OUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "output"))
os.makedirs(OUT_DIR, exist_ok=True)


def dedupe_leftmost_longest(matches):
    """Collapse overlapping matches to the classic leftmost-longest,
    non-overlapping set (like a real regex `search` sweep)."""
    matches = sorted(matches, key=lambda m: (m[0], -(m[1] - m[0])))
    result = []
    next_allowed = 0
    for start, end in matches:
        if start >= next_allowed:
            result.append((start, end))
            next_allowed = end
    return result


def main():
    print("=" * 70)
    print("CANDLELANG — Week 1 pipeline demo (synthetic data)")
    print("=" * 70)

    candles = generate_synthetic_candles(n=250)
    candle_string = encode_candles(candles)

    print(f"\nGenerated {len(candles)} synthetic daily candles.")
    print(f"Encoded candle string (alphabet U/D/F/G), length {len(candle_string)}:\n")
    for i in range(0, len(candle_string), 60):
        print(" ", candle_string[i:i + 60])

    print("\n" + "-" * 70)
    print("Symbol frequency:")
    for sym in "UDFG":
        print(f"  {sym}: {candle_string.count(sym):4d}  ({candle_string.count(sym)/len(candle_string):.1%})")

    print("\n" + "=" * 70)
    print("PATTERN MATCHING (regex -> Thompson NFA -> substring search)")
    print("=" * 70)

    report_lines = []
    diagrams_made = []

    for name, spec in PATTERNS.items():
        if not spec["regular"]:
            print(f"\n[{name}] SKIPPED for automaton matching — {spec['meaning']}")
            report_lines.append((name, spec["meaning"], None, None))
            continue

        regex = spec["regex"]
        nfa = regex_to_nfa(regex)
        raw_matches = search_substrings(nfa, candle_string)
        matches = dedupe_leftmost_longest(raw_matches)

        # Build + minimize the DFA, then independently re-verify each match
        dfa = subset_construction(nfa)
        min_dfa = minimize_dfa(dfa)
        verified = all(min_dfa.accepts_string(candle_string[s:e]) for s, e in matches)

        print(f"\n[{name}]  /{regex}/   — {spec['meaning']}")
        print(f"    NFA states: {nfa.num_states}   DFA states: {dfa.num_states}   "
              f"Minimized DFA states: {min_dfa.num_states}")
        print(f"    Occurrences found: {len(matches)}   "
              f"DFA cross-check: {'PASS' if verified else 'FAIL'}")
        for s, e in matches[:5]:
            print(f"      -> position {s:3d}-{e:3d}: {candle_string[s:e]}")
        if len(matches) > 5:
            print(f"      ... and {len(matches) - 5} more")

        report_lines.append((name, spec["meaning"], regex, len(matches)))

        if name in ("three_white_soldiers", "bullish_reversal"):
            nfa_path = os.path.join(OUT_DIR, f"nfa_{name}.png")
            dfa_path = os.path.join(OUT_DIR, f"dfa_min_{name}.png")
            try:
                draw_nfa(nfa, f"NFA for /{regex}/  ({name})", nfa_path)
                draw_dfa(min_dfa, f"Minimized DFA for /{regex}/  ({name})", dfa_path)
                diagrams_made += [nfa_path, dfa_path]
                print(f"    Saved diagrams: {os.path.basename(nfa_path)}, {os.path.basename(dfa_path)}")
            except OSError as e:
                print(f"    (diagram save skipped this run — file-system hiccup: {e})")

            table_path = os.path.join(OUT_DIR, f"dfa_table_{name}.txt")
            with open(table_path, "w") as tf:
                tf.write(f"Minimized DFA transition table for /{regex}/  ({name})\n")
                tf.write(f"Start state: q{min_dfa.start}   Accepting state(s): "
                         f"{{{', '.join('q'+str(s) for s in sorted(min_dfa.accepts))}}}\n")
                tf.write("(Missing entries go to an implicit dead/trap state -- omitted for clarity)\n\n")
                tf.write(f"{'state':<8}" + "".join(f"{sym:<6}" for sym in 'UDFG') + "accepting?\n")
                for s in range(min_dfa.num_states):
                    row = f"q{s:<7}"
                    for sym in 'UDFG':
                        tgt = min_dfa.transitions.get(s, {}).get(sym)
                        row += f"{('q'+str(tgt)) if tgt is not None else '-':<6}"
                    row += "yes" if s in min_dfa.accepts else "no"
                    tf.write(row + "\n")
            print(f"    Saved transition table: {os.path.basename(table_path)}")

    # Save the raw candle string + summary for the report
    with open(os.path.join(OUT_DIR, "candle_string.txt"), "w") as f:
        f.write(candle_string + "\n")

    with open(os.path.join(OUT_DIR, "match_summary.txt"), "w") as f:
        f.write("CandleLang — pattern match summary (synthetic 250-day series)\n")
        f.write("=" * 60 + "\n\n")
        for name, meaning, regex, count in report_lines:
            if regex is None:
                f.write(f"{name}: NOT run through FA (needs numeric check) — {meaning}\n\n")
            else:
                f.write(f"{name}  /{regex}/  -> {count} occurrence(s)\n    {meaning}\n\n")

    print("\n" + "=" * 70)
    print(f"Diagrams and summary written to: {os.path.abspath(OUT_DIR)}")
    print("=" * 70)


if __name__ == "__main__":
    main()
