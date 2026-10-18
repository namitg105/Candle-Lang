# CandleLang

**A formal regular-language engine for candlestick pattern detection with ML-based confidence scoring, built from first principles — regex → NFA (Thompson's Construction) → DFA (Subset Construction) → minimized DFA (Moore's algorithm) — with no external regex library, plus a logistic regression confidence layer and a Flutter front end.**

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
5. Each automaton match is scored by a **logistic regression ML classifier** against historical forward returns, so a match becomes "found, and this has worked X% of the time historically" instead of a bare yes/no.
6. The whole pipeline is delivered as a **Flutter app**: candlestick chart with highlighted matches and confidence scores.

## Why build the automaton by hand instead of using `re`?

Because the assignment isn't "detect candlestick patterns" — plenty of libraries already do that. It's "demonstrate understanding of regular languages and finite automata" applied to a real domain instead of a textbook string. Hand-building the regex → NFA → DFA → minimized-DFA pipeline is what makes every match **provably correct and explainable**, state by state, rather than a black box.

One pattern — *Double Top* — is a deliberate worked example of where a regular language stops being enough: the up-down-up-down *shape* (`U+DU+D`) is regular, but checking the two peaks are a *similar height* compares real-valued magnitudes, which needs a numeric check outside what a finite automaton can express. That limitation is documented, not hidden — see `src/patterns.py`.

## Repository layout

```
CandleLang/
├── README.md
├── LICENSE
├── requirements.txt
├── src/                          # the pipeline — all hand-written, no `re` module
│   ├── candle_encoder.py         # OHLC candles -> {U,D,F,G} string
│   ├── patterns.py               # trading patterns as regexes + double_top post-filter
│   ├── regex_ast.py              # hand-written regex parser (recursive descent)
│   ├── nfa.py                    # Thompson's Construction + NFA substring search
│   ├── subset_construction.py    # Subset Construction (NFA->DFA) + Moore's minimization
│   ├── data_fetcher.py           # real internet-sourced OHLC data
│   ├── ml_model.py               # logistic regression confidence scoring (pure numpy)
│   ├── visualize.py              # renders NFA/DFA state diagrams (networkx + matplotlib)
│   ├── synthetic_data.py         # synthetic OHLC generator (fallback)
│   └── demo.py                   # end-to-end pipeline demo — run this
├── output/                       # generated output (diagrams, tables, results)
│   ├── results.md                # results table (Markdown)
│   ├── results.json              # full export for Flutter app
│   ├── candle_string.txt         # the encoded {U,D,F,G} string
│   ├── encoding_trace.csv        # per-candle encoding breakdown
│   ├── match_summary.txt         # human-readable match summary
│   ├── diagrams/                 # NFA and minimized DFA state diagrams (PNG)
│   ├── transition_tables/        # DFA transition tables (CSV)
│   └── dfa_table_*.txt           # readable transition tables
├── flutter_app/                  # Flutter front end
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/               # data models (candle, pattern_match)
│   │   ├── widgets/              # candlestick chart, pattern cards
│   │   ├── screens/              # home screen
│   │   └── services/             # JSON data loader
│   ├── assets/                   # place results.json here
│   └── pubspec.yaml
└── docs/
    ├── PROJECT_PROPOSAL.md
    ├── PROGRESS_REPORT.md
    └── *.docx
```

## Running the Python pipeline

```bash
pip install numpy pandas matplotlib networkx
cd src
python demo.py
```

This fetches real AAPL historical OHLC data (506 trading days, Feb 2015 – Feb 2017) from a public GitHub-hosted dataset, encodes it into a `{U,D,F,G}` string, runs every pattern's automaton against it, cross-verifies every NFA match against the minimized DFA, trains an ML confidence model, and writes state-diagram images, transition tables, and results to `../output/`.

If the network source is unreachable, it falls back to synthetic data automatically.

## Running the Flutter app

```bash
# 1. Generate the data
cd src && python demo.py && cd ..

# 2. Copy the JSON export into the Flutter app's assets
cp output/results.json flutter_app/assets/

# 3. Run the app
cd flutter_app
flutter pub get
flutter run
```

The Flutter app loads `results.json`, renders a scrollable candlestick chart, and lets you tap any pattern to see its matches highlighted on the chart with ML confidence scores.

## Patterns implemented

| Pattern | Regex | Type | Meaning |
|---|---|---|---|
| Three White Soldiers | `U{3,}` | Regular | 3+ consecutive up-candles — bullish continuation |
| Three Black Crows | `D{3,}` | Regular | 3+ consecutive down-candles — bearish continuation |
| Bullish Reversal | `D+FU+` | Regular | Downtrend, pause, then upside resumes |
| Bearish Reversal | `U+FD+` | Regular | Uptrend, pause, then downside resumes |
| Gap and Go | `GU+` | Regular | Gap open followed by sustained upside |
| Exhaustion Gap | `U{2,}GD` | Regular | Run-up, gap, then immediate reversal down |
| Indecision Cluster | `F{2,}` | Regular | 2+ flat/doji candles — market undecided |
| Double Top | `U+DU+D` (shape) | **Hybrid** | Regular shape + numeric peak-height post-check outside the automaton |

## Demo results (real AAPL data, 506 candles)

All 7 regular patterns: **NFA/DFA cross-check PASS** — concrete proof of NFA/DFA equivalence.

The Double Top hybrid pattern demonstrates the boundary of regular languages: the *shape* is detected by the automaton, but the *similar peak height* condition requires a numeric comparison that no finite automaton can express.

ML confidence model trained on all pattern matches with 5-day forward returns.

## Architecture

```
OHLC price data
    │
    ▼
┌─────────────────────┐
│  candle_encoder.py   │  OHLC → {U, D, F, G}*
└─────────┬───────────┘
          │  encoded string
          ▼
┌─────────────────────┐     ┌──────────────────────┐
│   regex_ast.py      │ ──▶ │      nfa.py          │
│  recursive-descent  │     │ Thompson's           │
│  regex parser       │     │ Construction + search │
└─────────────────────┘     └──────────┬───────────┘
                                       │  NFA matches
                                       ▼
                            ┌──────────────────────┐
                            │subset_construction.py │
                            │ Subset Construction   │
                            │ + Moore's minimization│
                            └──────────┬───────────┘
                                       │  minimized DFA
                                       ▼
                            ┌──────────────────────┐
                            │    Cross-check:       │
                            │  NFA matches == DFA   │
                            │  (equivalence proof)  │
                            └──────────┬───────────┘
                                       │
                                       ▼
                            ┌──────────────────────┐
                            │    ml_model.py        │
                            │ Logistic regression   │
                            │ confidence scoring    │
                            └──────────┬───────────┘
                                       │
                                       ▼
                            ┌──────────────────────┐
                            │   Flutter app         │
                            │ Chart + highlights    │
                            │ + confidence display  │
                            └──────────────────────┘
```

## Status

**Project complete.** All five weeks of the project plan are implemented:
- Week 1: regex → NFA → DFA → minimization pipeline (hand-built, no `re`)
- Week 2: real internet-sourced market data, double_top numeric post-filter
- Week 3: ML logistic regression confidence model
- Week 4: Flutter app with candlestick chart and pattern highlights
- Week 5: documentation, diagrams, final polish

## License

MIT — see [`LICENSE`](LICENSE).
