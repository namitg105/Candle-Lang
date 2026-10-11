# CandleLang

**A formal regular-language engine for candlestick pattern detection, built from first principles — regex → NFA (Thompson's Construction) → DFA (Subset Construction) → minimized DFA (Moore's algorithm) — with no external regex library, plus a planned ML confidence layer and a Flutter front end.**

> Models of Computation (BCSE302L / BACSE202) course project — Vellore Institute of Technology
> Namit Gupta · Reg. No. 25BDE0068

---

## The idea

Technical analysts look for recurring candlestick patterns — *Three White Soldiers*, *Double Top*, *Bullish Engulfing* — in stock charts to anticipate short-term price movement. Existing charting platforms (TradingView and friends) detect these with hardcoded, closed-source rules: you get a "pattern found" badge with no way to see why, or how reliable that signal actually is.

CandleLang reframes candlestick pattern detection as a **formal language recognition problem**:

1. Every candle in a stock's price history is mapped to a symbol over a 4-letter alphabet — `U` (up), `D` (down), `F` (flat), `G` (gap) — turning a price history into a string.
2. Known trading patterns are written as **regular expressions** over that alphabet (`U{3,}` for Three White Soldiers, `D+FU+` for a bullish reversal, etc.).
3. Each regex is compiled into its own automaton **by hand** — Thompson's Construction (regex → NFA), Subset Construction (NFA → DFA), and Moore's partition-refinement minimization (DFA → minimal DFA) — with no use of Python's `re` module anywhere in the matching path.
4. Every match the NFA finds is independently **cross-verified** against the derived minimal DFA, which is a live demonstration of NFA/DFA language equivalence, not just a textbook claim.
5. *(Planned)* each automaton match is scored by a lightweight ML classifier against historical outcomes, so a match becomes "found, and this has worked X% of the time historically" instead of a bare yes/no.
6. *(Planned)* the whole pipeline is delivered as a Flutter app: live candlestick chart, highlighted matches, confidence score.

See [`docs/PROJECT_PROPOSAL.md`](docs/PROJECT_PROPOSAL.md) for the full course proposal and [`docs/PROGRESS_REPORT.md`](docs/PROGRESS_REPORT.md) for the current build status.

## Why build the automaton by hand instead of using `re`?

Because the assignment isn't "detect candlestick patterns" — plenty of libraries already do that. It's "demonstrate understanding of regular languages and finite automata" applied to a real domain instead of a textbook string. Hand-building the regex → NFA → DFA → minimized-DFA pipeline is what makes every match **provably correct and explainable**, state by state, rather than a black box.

One pattern — *Double Top* — is a deliberate worked example of where a regular language stops being enough: the up-down-up-down *shape* (`U+DU+D`) is regular, but checking the two peaks are a *similar height* compares real-valued magnitudes, which needs a numeric check outside what a finite automaton can express. That limitation is documented, not hidden — see `patterns.py`.

## Repository layout

```
CandleLang/
├── README.md
├── LICENSE
├── requirements.txt
├── src/                          # the actual pipeline — all hand-written, no `re` module
│   ├── candle_encoder.py         # OHLC candles -> {U,D,F,G} string
│   ├── patterns.py                # trading patterns as regexes over {U,D,F,G}
│   ├── regex_ast.py               # hand-written regex parser (recursive descent)
│   ├── nfa.py                     # Thompson's Construction + NFA substring search
│   ├── subset_construction.py     # Subset Construction (NFA->DFA) + Moore's minimization
│   ├── visualize.py                # renders NFA/DFA state diagrams (networkx + matplotlib)
│   ├── synthetic_data.py          # realistic synthetic OHLC generator for demos
│   └── demo.py                     # end-to-end pipeline demo — run this
├── output/                        # sample output from a demo run (diagrams, tables, logs)
└── docs/
    ├── PROJECT_PROPOSAL.md         # official course project proposal
    ├── PROGRESS_REPORT.md          # Review 1 progress snapshot
    ├── CandleLang_Project_Proposal.docx
    └── CandleLang_Progress_Report.docx
```

## Running the demo

```bash
pip install numpy pandas matplotlib networkx
cd src
python demo.py
```

This generates a 250-day synthetic OHLC series (live market APIs aren't wired in yet — see roadmap), encodes it, runs every pattern's automaton against it, cross-verifies every match against the minimized DFA, and writes state-diagram images and transition tables to `../output/`.

## Patterns implemented

| Pattern | Regex | Meaning |
|---|---|---|
| Three White Soldiers | `U{3,}` | 3+ consecutive up-candles — bullish continuation |
| Three Black Crows | `D{3,}` | 3+ consecutive down-candles — bearish continuation |
| Bullish Reversal | `D+FU+` | Downtrend, pause, then upside resumes |
| Bearish Reversal | `U+FD+` | Uptrend, pause, then downside resumes |
| Gap and Go | `GU+` | Gap open followed by sustained upside |
| Exhaustion Gap | `U{2,}GD` | Run-up, gap, then immediate reversal down |
| Indecision Cluster | `F{2,}` | 2+ flat/doji candles — market undecided |
| Double Top (hybrid) | `U+DU+D` (shape only) | Regular shape + a numeric peak-height post-check outside the automaton |

## Status

**~25% complete.** The regex → NFA → DFA → minimization pipeline is built, tested, and demonstrated end-to-end on synthetic data, with DFA minimization pulled forward from its originally planned week. Live market data, the ML confidence layer, and the Flutter app are not yet built — see [`docs/PROGRESS_REPORT.md`](docs/PROGRESS_REPORT.md) for the detailed week-by-week breakdown.

## License

MIT — see [`LICENSE`](LICENSE).
