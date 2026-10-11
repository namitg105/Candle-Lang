# CandleLang — Review 1 Progress Snapshot (2026-09-07)

**Status: ~25% complete (Week 1 of a 5-week plan done; DFA minimization pulled forward from Week 2).**

A full write-up with architecture tables, results, and state-diagram figures is in [`CandleLang_Progress_Report.docx`](CandleLang_Progress_Report.docx). This file is the condensed version.

## What's built and verified (working code, not pseudocode)

- `candle_encoder.py` — deterministic OHLC → `{U,D,F,G}` string encoder (gap-priority rule documented).
- `patterns.py` — 7 candlestick patterns as regexes over `{U,D,F,G}`, plus `double_top` documented as a hybrid pattern (regular shape `U+DU+D` + a numeric peak-height post-check that's outside what a regular language can express — this distinction is the TOC-depth argument for the write-up/defense).
- `regex_ast.py` + `nfa.py` — hand-written recursive-descent regex parser and **Thompson's Construction** (no `re` module used anywhere).
- `nfa.py::search_substrings` — multi-threaded NFA simulation (grep-style) finding every match position.
- `subset_construction.py` — **Subset Construction** (NFA→DFA) and **Moore's minimization** (DFA→minimal DFA).
- `visualize.py` — renders NFA/DFA state diagrams via networkx + matplotlib (no graphviz binary dependency).
- `demo.py` — end-to-end run on a 250-day **synthetic** OHLC series (live market APIs are Week 3 work per the original plan, and need zero changes to the automaton code, since everything operates on the encoded string).
- Every pattern match found by the NFA was independently **cross-verified by the minimized DFA** — concrete proof of NFA/DFA equivalence, not just a claim.

## Demo results (synthetic 250-candle series)

| Pattern | NFA states | Min DFA states | Occurrences | DFA cross-check |
|---|---|---|---|---|
| Three White Soldiers (`U{3,}`) | 10 | 4 | 12 | PASS |
| Three Black Crows (`D{3,}`) | 10 | 4 | 13 | PASS |
| Bullish Reversal (`D+FU+`) | 14 | 4 | 5 | PASS |
| Bearish Reversal (`U+FD+`) | 14 | 4 | 4 | PASS |
| Gap and Go (`GU+`) | 8 | 3 | 8 | PASS |
| Exhaustion Gap (`U{2,}GD`) | 12 | 5 | 1 | PASS |
| Indecision Cluster (`F{2,}`) | 8 | 3 | 2 | PASS |

## Not yet built (honestly scoped, next up)

- **Week 2** — live market-data integration, expanded pattern set, numeric post-filter for hybrid patterns like Double Top.
- **Week 3** — historical pattern-outcome dataset + logistic regression confidence model.
- **Week 4** — Flutter app (chart rendering, live matches, confidence display).
- **Week 5** — polish, final diagrams, write-up, defense rehearsal.
