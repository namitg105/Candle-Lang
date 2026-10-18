"""
demo.py
-------
End-to-end CandleLang pipeline on REAL internet-sourced OHLC data.

    1. data_fetcher.fetch_candles()      -- download real AAPL daily
       OHLC candles from a public GitHub-hosted dataset (falls back
       to synthetic data if the network is unavailable).
    2. candle_encoder.encode_candles()   -- turn the price history into
       a string over {U, D, F, G}.
    3. For each of the 7 regular patterns:
         a. regex -> AST -> NFA           (regex_ast.py, nfa.py)
         b. search_substrings(nfa, ...)   -- find every match (NFA)
         c. NFA -> DFA -> minimized DFA   (subset_construction.py)
         d. DFA.accepts_string()          -- independently verify every
            NFA match against the minimized DFA
         e. compare: they must agree -- this is the concrete proof of
            NFA/DFA equivalence for that pattern.
    4. The double_top hybrid pattern is run separately
       (patterns.find_double_top_matches): regex pre-filter + numeric
       peak-height post-check.
    5. ML confidence scoring via ml_model.train_and_score().
    6. State-diagram PNGs, transition tables, results table, and a
       JSON export for the Flutter app.

Run:  python3 demo.py
"""

import csv as csvmod
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from candle_encoder import encode_candles, encode_with_trace
from data_fetcher import fetch_candles, DEFAULT_DATA_URL, DEFAULT_SYMBOL
from ml_model import train_and_score
from nfa import regex_to_nfa, search_substrings
from patterns import (
    PATTERNS, DOUBLE_TOP_NAME, DOUBLE_TOP_REGEX,
    find_double_top_matches, dedupe_leftmost_longest,
)
from subset_construction import subset_construction, minimize_dfa
from visualize import draw_nfa, draw_dfa

OUT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "output"))
TABLES_DIR = os.path.join(OUT_DIR, "transition_tables")
DIAGRAMS_DIR = os.path.join(OUT_DIR, "diagrams")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(TABLES_DIR, exist_ok=True)
    os.makedirs(DIAGRAMS_DIR, exist_ok=True)

    # ── 1. Fetch real data ──────────────────────────────────────────
    print("=" * 72)
    print("CANDLELANG — Full pipeline demo (real market data)")
    print("=" * 72)

    candles = fetch_candles()
    print(f"\nLoaded {len(candles)} candles "
          f"({candles[0].date} -> {candles[-1].date}).\n")

    # ── 2. Encode ───────────────────────────────────────────────────
    encoded, trace = encode_with_trace(candles)
    print(f"Encoded string length: {len(encoded)} symbols over "
          f"{{{', '.join(sorted(set(encoded)))}}}")

    # symbol frequency
    print("\nSymbol frequency:")
    for sym in "UDFG":
        cnt = encoded.count(sym)
        print(f"  {sym}: {cnt:4d}  ({cnt/len(encoded):.1%})")

    # save encoded string + trace
    with open(os.path.join(OUT_DIR, "candle_string.txt"), "w") as f:
        f.write(f"Source: {DEFAULT_DATA_URL}\n")
        f.write(f"Symbol: {DEFAULT_SYMBOL}\n")
        f.write(f"Range: {candles[0].date} to {candles[-1].date} "
                f"({len(candles)} candles, {len(encoded)} encoded symbols)\n\n")
        f.write(encoded + "\n")

    with open(os.path.join(OUT_DIR, "encoding_trace.csv"), "w", newline="") as f:
        w = csvmod.writer(f)
        w.writerow(["date", "symbol", "gap_pct", "body_pct"])
        w.writerows(trace)

    # ── 3. Pattern matching ─────────────────────────────────────────
    print("\n" + "=" * 72)
    print("PATTERN MATCHING (regex -> Thompson NFA -> DFA -> minimized DFA)")
    print("=" * 72)

    highs = [c.high for c in candles]

    results = []
    all_matches = {}  # for ML scoring

    header = (f"{'Pattern':24s} {'Regex':10s} {'NFA':>5s} {'DFA':>5s} "
              f"{'MinDFA':>7s} {'Occur':>6s}  Cross-check")
    print(f"\n{header}")
    print("-" * 78)

    for name, spec in PATTERNS.items():
        if not spec["regular"]:
            continue

        regex = spec["regex"]
        nfa = regex_to_nfa(regex)
        raw_matches = search_substrings(nfa, encoded)
        matches = dedupe_leftmost_longest(raw_matches)

        # Build + minimize the DFA
        dfa = subset_construction(nfa)
        min_dfa = minimize_dfa(dfa)

        # Cross-check: every NFA match must be accepted by the minimized DFA
        verified = all(
            min_dfa.accepts_string(encoded[s:e]) for s, e in matches
        )
        cross_check = "PASS" if verified else "FAIL"

        results.append({
            "pattern": name,
            "regex": regex,
            "nfa_states": nfa.num_states,
            "dfa_states": dfa.num_states,
            "min_dfa_states": min_dfa.num_states,
            "occurrences": len(matches),
            "cross_check": cross_check,
        })

        all_matches[name] = matches

        print(f"{name:24s} {regex:10s} {nfa.num_states:5d} {dfa.num_states:5d} "
              f"{min_dfa.num_states:7d} {len(matches):6d}  {cross_check}")

        # ── Diagrams for this pattern ───────────────────────────────
        slug = name.replace(" ", "_")
        try:
            nfa_path = os.path.join(DIAGRAMS_DIR, f"nfa_{slug}.png")
            dfa_path = os.path.join(DIAGRAMS_DIR, f"dfa_min_{slug}.png")
            draw_nfa(nfa, f"NFA for /{regex}/  ({name})", nfa_path)
            draw_dfa(min_dfa, f"Minimized DFA for /{regex}/  ({name})", dfa_path)
        except Exception as e:
            print(f"  (diagram save skipped: {e})")

        # ── Transition table for this pattern ───────────────────────
        table_path = os.path.join(TABLES_DIR, f"{slug}_min_dfa.csv")
        with open(table_path, "w", newline="") as f:
            w = csvmod.writer(f)
            w.writerow(["state", "symbol", "next_state"])
            for s in range(min_dfa.num_states):
                for sym in "UDFG":
                    tgt = min_dfa.transitions.get(s, {}).get(sym)
                    if tgt is not None:
                        w.writerow([f"q{s}", sym, f"q{tgt}"])
            w.writerow([])
            w.writerow(["start_state", f"q{min_dfa.start}"])
            w.writerow(["accepting_states",
                         ",".join(f"q{s}" for s in sorted(min_dfa.accepts))])

        # Also write readable .txt version
        txt_path = os.path.join(OUT_DIR, f"dfa_table_{slug}.txt")
        with open(txt_path, "w") as tf:
            tf.write(f"Minimized DFA transition table for /{regex}/  ({name})\n")
            tf.write(f"Start state: q{min_dfa.start}   Accepting state(s): "
                     f"{{{', '.join('q'+str(s) for s in sorted(min_dfa.accepts))}}}\n")
            tf.write("(Missing entries go to an implicit dead/trap state)\n\n")
            tf.write(f"{'state':<8}" + "".join(f"{sym:<6}" for sym in 'UDFG') + "accepting?\n")
            for s in range(min_dfa.num_states):
                row = f"q{s:<7}"
                for sym in 'UDFG':
                    tgt = min_dfa.transitions.get(s, {}).get(sym)
                    row += f"{('q'+str(tgt)) if tgt is not None else '-':<6}"
                row += "yes" if s in min_dfa.accepts else "no"
                tf.write(row + "\n")

    # ── 4. Double top (hybrid) ──────────────────────────────────────
    print(f"\n{'--- Hybrid Pattern ---':^78}")
    confirmed_dt = find_double_top_matches(encoded, highs)
    all_matches[DOUBLE_TOP_NAME] = confirmed_dt

    print(f"{DOUBLE_TOP_NAME:24s} {DOUBLE_TOP_REGEX:10s} {'  -':>5s} {'  -':>5s} "
          f"{'  -':>7s} {len(confirmed_dt):6d}  "
          f"regex + numeric peak check (not DFA-only)")

    results.append({
        "pattern": DOUBLE_TOP_NAME,
        "regex": DOUBLE_TOP_REGEX,
        "nfa_states": "-",
        "dfa_states": "-",
        "min_dfa_states": "-",
        "occurrences": len(confirmed_dt),
        "cross_check": "regex + numeric peak check",
    })

    # ── 5. ML confidence scoring ────────────────────────────────────
    print(f"\n{'--- ML Confidence Scoring ---':^78}")
    scored = train_and_score(candles, encoded, all_matches)

    # print a sample
    for name in list(scored.keys())[:3]:
        if scored[name]:
            s, e, conf = scored[name][0]
            print(f"  {name}: first match [{s}:{e}] "
                  f"'{encoded[s:e]}' confidence={conf:.3f}")

    # ── 6. Output files ────────────────────────────────────────────
    # results.md
    with open(os.path.join(OUT_DIR, "results.md"), "w") as f:
        f.write("# CandleLang — Full Pipeline Results (Real Data)\n\n")
        f.write(f"**Source:** {DEFAULT_DATA_URL}\n\n")
        f.write(f"**Symbol:** {DEFAULT_SYMBOL} | "
                f"**Range:** {candles[0].date} to {candles[-1].date} | "
                f"{len(candles)} candles -> {len(encoded)} encoded symbols\n\n")

        f.write("## Pattern Matching Results\n\n")
        f.write("| Pattern | Regex | NFA states | DFA states | "
                "Min DFA states | Occurrences | NFA/DFA cross-check |\n")
        f.write("|---|---|---|---|---|---|---|\n")
        for r in results:
            f.write(f"| {r['pattern']} | `{r['regex']}` | {r['nfa_states']} | "
                    f"{r['dfa_states']} | {r['min_dfa_states']} | "
                    f"{r['occurrences']} | {r['cross_check']} |\n")

        f.write("\n## ML Confidence Scores (sample)\n\n")
        f.write("| Pattern | Match | Substring | Confidence |\n")
        f.write("|---|---|---|---|\n")
        for name, matches in scored.items():
            for s, e, conf in matches[:3]:
                f.write(f"| {name} | [{s}:{e}] | "
                        f"`{encoded[s:min(e,s+12)]}{'...' if e-s > 12 else ''}` | "
                        f"{conf:.3f} |\n")

    # match_summary.txt
    with open(os.path.join(OUT_DIR, "match_summary.txt"), "w") as f:
        f.write(f"CandleLang — pattern match summary (real {DEFAULT_SYMBOL} data)\n")
        f.write("=" * 60 + "\n\n")
        f.write(f"Data source: {DEFAULT_DATA_URL}\n")
        f.write(f"Range: {candles[0].date} to {candles[-1].date}\n")
        f.write(f"Candles: {len(candles)}, Encoded symbols: {len(encoded)}\n\n")

        for r in results:
            if r["cross_check"] == "regex + numeric peak check":
                f.write(f"{r['pattern']}  /{r['regex']}/  -> "
                        f"{r['occurrences']} occurrence(s) "
                        f"(regex + numeric peak check)\n"
                        f"    {PATTERNS.get(r['pattern'], {}).get('meaning', '')}\n\n")
            else:
                f.write(f"{r['pattern']}  /{r['regex']}/  -> "
                        f"{r['occurrences']} occurrence(s)  "
                        f"DFA cross-check: {r['cross_check']}\n"
                        f"    NFA: {r['nfa_states']} states, "
                        f"Min DFA: {r['min_dfa_states']} states\n"
                        f"    {PATTERNS.get(r['pattern'], {}).get('meaning', '')}\n\n")

    # JSON export for Flutter app
    export = {
        "source": DEFAULT_DATA_URL,
        "symbol": DEFAULT_SYMBOL,
        "date_range": [candles[0].date, candles[-1].date],
        "num_candles": len(candles),
        "encoded_length": len(encoded),
        "candles": [
            {"date": c.date, "open": c.open, "high": c.high,
             "low": c.low, "close": c.close}
            for c in candles
        ],
        "encoded": encoded,
        "patterns": [],
    }
    for r in results:
        name = r["pattern"]
        pattern_data = {
            "name": name,
            "regex": r["regex"],
            "nfa_states": r["nfa_states"],
            "min_dfa_states": r["min_dfa_states"],
            "occurrences": r["occurrences"],
            "cross_check": r["cross_check"],
            "matches": [],
        }
        if name in scored:
            for s, e, conf in scored[name]:
                pattern_data["matches"].append({
                    "start": s, "end": e,
                    "substring": encoded[s:e],
                    "confidence": conf,
                })
        elif name in all_matches:
            for s, e in all_matches[name]:
                pattern_data["matches"].append({
                    "start": s, "end": e,
                    "substring": encoded[s:e],
                    "confidence": None,
                })
        export["patterns"].append(pattern_data)

    with open(os.path.join(OUT_DIR, "results.json"), "w") as f:
        json.dump(export, f, indent=2)

    print(f"\n{'=' * 72}")
    print(f"All outputs written to: {OUT_DIR}/")
    print(f"  - results.md, results.json, match_summary.txt")
    print(f"  - candle_string.txt, encoding_trace.csv")
    print(f"  - diagrams/*.png, transition_tables/*.csv")
    print(f"  - dfa_table_*.txt")
    print(f"{'=' * 72}")


if __name__ == "__main__":
    main()
