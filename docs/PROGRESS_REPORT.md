# CandleLang — Progress Report

**Course:** Models of Computation (BCSE302L / BACSE202)
**Student:** Namit Gupta · Reg. No. 25BDE0068
**Institute:** Vellore Institute of Technology

---

## Summary

CandleLang reframes candlestick pattern detection as a formal language recognition problem: OHLC price history is encoded over a 4-letter alphabet `{U, D, F, G}`, known trading patterns are written as regular expressions over that alphabet, and each regex is compiled by hand — Thompson's Construction (regex → NFA), Subset Construction (NFA → DFA), and Moore's partition-refinement minimization (DFA → minimal DFA) — with no use of any regex engine or library automaton implementation anywhere in the matching path.

The project went through two implementation phases. Weeks 1–3 built and validated the complete algorithm pipeline in Python against real market data, confirming the automaton theory was sound before committing to a UI. For the final deliverable, the entire pipeline — regex parser, NFA, DFA, minimization, pattern detection, and the ML confidence model — was reimplemented from scratch in pure Dart, and the project now ships as a single Flutter application with **zero Python dependencies and no external backend**, organized under Clean Architecture (domain / data / presentation layers, feature-first).

---

## Week 1 — Regex → NFA → DFA → Minimization Pipeline

**Goal:** Build the complete automaton pipeline from scratch, with no use of a library regex engine.

- **Regex parser:** Hand-written recursive-descent parser producing an AST (`Char`, `Epsilon`, `Concat`, `Union`, `Star` nodes). Supports concatenation, alternation (`|`), Kleene star (`*`), plus (`+`), optional (`?`), and bounded repetition (`{n,}`).
- **Thompson's Construction:** Converts the AST into an ε-NFA. Each AST node maps to a small NFA fragment joined by ε-transitions; the resulting NFA has exactly one start state and one accept state.
- **NFA substring search:** Thread-based grep-style search that tries the NFA starting at every position in the input string, collecting all match spans.
- **Subset Construction:** Converts the ε-NFA into a DFA via the standard powerset construction, tracking which NFA state-set each DFA state represents.
- **Moore's minimization:** Partition-refinement algorithm that merges equivalent DFA states into the minimal DFA.

**Patterns defined:** seven regular patterns and one hybrid pattern over `{U, D, F, G}`:

| Pattern | Regex | Type |
|---|---|---|
| Three White Soldiers | `U{3,}` | Regular |
| Three Black Crows | `D{3,}` | Regular |
| Bullish Reversal | `D+FU+` | Regular |
| Bearish Reversal | `U+FD+` | Regular |
| Gap and Go | `GU+` | Regular |
| Exhaustion Gap | `U{2,}GD` | Regular |
| Indecision Cluster | `F{2,}` | Regular |
| Double Top | `U+DU+D` (shape) | Hybrid |

This phase was validated in Python (`regex_ast.py`, `nfa.py`, `subset_construction.py`); the algorithms carried over unchanged into the Dart rewrite described below.

---

## Week 2 — Real Market Data & Double Top Post-Filter

**Goal:** Connect to real internet-sourced OHLC data and implement the hybrid Double Top pattern.

- **Data source:** Real AAPL historical OHLC data (506 trading days, Feb 2015 – Feb 2017) from a public GitHub-hosted dataset (`plotly/datasets`), with an offline bundled fallback.
- **Candle encoding:** Each OHLC candle maps to a symbol — `U` (up), `D` (down), `F` (flat/doji), `G` (gap). Gap detection uses a 0.5% threshold on `(open − prev_close) / prev_close` and takes priority over body classification, which uses a 0.3% threshold on `(close − open) / open`.
- **Double Top hybrid pattern:** The shape `U+DU+D` is regular and detected by the automaton. The "similar peak height" condition — checking the two peaks are within 1.5% of each other — requires a numeric comparison outside what a finite automaton can express. This is implemented as a regex pre-filter (automaton match) followed by a numeric post-check, and is the project's concrete demonstration of where regular languages reach their limit.
- **Leftmost-longest deduplication:** non-overlapping match spans are reported, keeping the earliest and longest match at each position.

**Encoding statistics on real AAPL data (506 candles):** U 26.3%, D 25.3%, F 8.5%, G 39.9%. The high gap frequency reflects the 0.5% threshold applied to real daily data, where overnight gaps between close and next-day open are common.

---

## Week 3 — ML Confidence Scoring

**Goal:** Train a machine-learning model to score each pattern match with a confidence value.

- **Logistic regression model:** implemented from scratch (no scikit-learn, no external ML library) — gradient descent with z-score feature normalization.
- **Feature engineering (11 features per match):** match length, relative position in the price history, local volatility (std. dev. of closes in the match window), pre-trend (5-candle return before the match), up-candle ratio, down-candle ratio, gap count, and a 4-way pattern category one-hot (bullish continuation / bearish continuation / reversal / gap pattern).
- **Labeling:** each match is labeled by whether the 5-day forward return aligns with the pattern's expected direction.
- **Training results:** 64 total match samples, ~69% training accuracy. The model outputs a 0–1 probability per match, shown in the app as a confidence percentage.

---

## Week 4 — Pivot to Pure Dart & Flutter App (Clean Architecture)

**Goal:** Deliver the pipeline as a real application rather than a script, and remove the Python/Flutter split in favor of one self-contained Dart codebase.

The initial plan shipped a Python backend pipeline that exported a JSON snapshot for a thin Flutter viewer. For the final deliverable this was replaced entirely: every algorithm — the regex parser, Thompson's Construction, Subset Construction, Moore's minimization, pattern detection, and the logistic regression model — was reimplemented in pure Dart, and the Python pipeline was removed from the repository. The app now fetches its own data, runs its own automata, and scores its own matches at runtime, with **zero Python dependencies and no external backend server**.

The codebase follows feature-first Clean Architecture under `flutter_app/lib/`:

```text
lib/
├── core/                      # Shared error types, base use case, theme
└── features/
    ├── encoding/              # OHLC fetch (remote + offline asset) and {U,D,F,G} encoding
    ├── automaton/              # Regex parser, Thompson/Subset/Moore, NFA search, DFA simulation
    ├── pattern_detection/      # The 8 trading patterns, including the Double Top hybrid check
    ├── ml_scoring/             # Pure-Dart logistic regression confidence model
    └── visualization/          # Orchestration (AnalysisBloc) and the main chart UI
```

Each feature keeps strict domain / data / (where applicable) presentation separation: domain entities and repository interfaces have no Flutter or I/O dependencies; data-layer repository implementations do the real work (HTTP fetch, automaton construction, regression); BLoCs mediate between use cases and widgets, which only ever dispatch events and render state.

**UI delivered:**
- **Market Chart** — candlestick chart with tap-to-highlight pattern matches and ML confidence badges.
- **Automata Theory Inspector** — a dedicated screen showing the regex AST, NFA/DFA/minimized-DFA state-reduction counts, the full DFA transition table, and an interactive string simulator against the minimized DFA.
- **Encoding Trace** — a per-candle table showing exactly why each candle was classified U/D/F/G.

Navigation is a bottom `NavigationBar` across these three screens, wired through `GetIt` dependency injection (`injection_container.dart`) and three BLoCs (`AnalysisBloc`, `AutomatonBloc`, `EncodingBloc`) provided at the app root.

---

## Week 5 — Testing, Documentation & Final Polish

**Goal:** Verify correctness, finalize documentation, and clean up the repository for submission.

- **Tests:** a pure-Dart unit test exercises the automaton pipeline directly (regex → NFA → DFA → minimized DFA → string simulation) without needing the Flutter widget tree, plus a widget test that boots the full app through dependency injection.
- **Repository cleanup:** the superseded Python pipeline and its generated output were retired now that the Dart implementation is the source of truth; transfer artifacts and stray build output were removed from version control.
- **Documentation:** `README.md` rewritten to describe the pure-Dart Clean Architecture, the pattern table, and how to run the app; this progress report rewritten to reflect the Python → Dart pivot rather than describing files that no longer exist.

---

## Conclusion

CandleLang demonstrates that candlestick pattern detection can be rigorously formulated as a formal language recognition problem, and that the resulting automata can be built, verified, and shipped entirely in Dart. The hand-built regex → NFA → DFA → minimized-DFA pipeline proves understanding of regular languages and finite automata; the Automata Theory Inspector makes that machinery inspectable rather than hidden; the Double Top hybrid pattern illustrates where regular languages reach their limits; and the ML confidence layer adds practical value by scoring each match against historical outcomes — all without leaving the Dart/Flutter ecosystem.
