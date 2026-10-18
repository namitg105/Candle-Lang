# CandleLang — Progress Report

**Course:** Models of Computation (BCSE302L / BACSE202)  
**Student:** Namit Gupta · Reg. No. 25BDE0068  
**Institute:** Vellore Institute of Technology  

---

## Week 1 — Regex → NFA → DFA → Minimization Pipeline

**Goal:** Build the complete automaton pipeline from scratch, with no use of Python's `re` module.

**Completed:**

- **Regex parser** (`regex_ast.py`): Hand-written recursive-descent parser producing an AST. Supports concatenation, alternation (`|`), Kleene star (`*`), plus (`+`), optional (`?`), and bounded repetition (`{n,}`). The AST nodes are `Char`, `Epsilon`, `Concat`, `Union`, and `Star`.
- **Thompson's Construction** (`nfa.py`): Converts a regex AST into an ε-NFA. Each AST node maps to a small NFA fragment with ε-transitions connecting them. The resulting NFA has exactly one start state and one accept state.
- **NFA substring search** (`nfa.py`): Thread-based grep-style search that tries the NFA starting at every position in the input string, collecting all match spans `(start, end)`.
- **Subset Construction** (`subset_construction.py`): Converts the ε-NFA into a DFA via the standard powerset/subset construction algorithm. Tracks which NFA state-sets correspond to each DFA state.
- **Moore's minimization** (`subset_construction.py`): Partition-refinement algorithm that merges equivalent DFA states, producing the minimal DFA. State labels are preserved for traceability.
- **Visualization** (`visualize.py`): Renders NFA and DFA state diagrams as PNG images using networkx and matplotlib. Start states are green, accept states are red, states that are both are purple.

**Patterns defined** (`patterns.py`): Seven regular patterns and one hybrid pattern over the alphabet `{U, D, F, G}`:

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

---

## Week 2 — Real Market Data & Double Top Post-Filter

**Goal:** Connect to real internet-sourced OHLC data and implement the hybrid Double Top pattern.

**Completed:**

- **Data fetcher** (`data_fetcher.py`): Fetches real AAPL historical OHLC data (506 trading days, Feb 2015 – Feb 2017) from a public GitHub-hosted dataset (`plotly/datasets`). Includes a Yahoo Finance live-data path for unrestricted networks and a synthetic-data fallback (`synthetic_data.py`) for offline use.
- **Candle encoder** (`candle_encoder.py`): Maps each OHLC candle to a symbol: `U` (up), `D` (down), `F` (flat/doji), `G` (gap). Gap detection uses a threshold of 0.5% on `(open − prev_close) / prev_close` and takes priority over the body classification. Body classification uses a 0.3% threshold on `(close − open) / open`. Added `encode_with_trace()` for per-candle encoding breakdown (date, symbol, gap%, body%).
- **Double Top hybrid pattern** (`patterns.py`): The shape `U+DU+D` is regular and detected by the automaton. The "similar peak height" condition — checking that the two peaks are within 1.5% of each other — requires a numeric comparison that no finite automaton can express. This is implemented as a regex pre-filter (NFA match) followed by a numeric post-check (`find_double_top_matches()`), and serves as the project's concrete demonstration of where regular languages reach their limit.
- **Leftmost-longest deduplication** (`patterns.py`): `dedupe_leftmost_longest()` ensures non-overlapping match spans are reported, keeping the earliest and longest match at each position.

**Encoding statistics on real AAPL data (506 candles):**

| Symbol | Count | Percentage |
|---|---|---|
| U (up) | 133 | 26.3% |
| D (down) | 128 | 25.3% |
| F (flat) | 43 | 8.5% |
| G (gap) | 202 | 39.9% |

The high gap frequency reflects the 0.5% threshold applied to real AAPL daily data, where overnight gaps between close and next-day open are common.

---

## Week 3 — ML Confidence Scoring

**Goal:** Train a machine-learning model to score each pattern match with a confidence value.

**Completed:**

- **Logistic regression model** (`ml_model.py`): Pure-Python implementation using numpy — no scikit-learn dependency. Trained with gradient descent and z-score feature normalization.
- **Feature engineering** (11 features per match):
  1. Match length (number of candles in the match span)
  2. Relative position (where in the price history the match occurs, 0–1)
  3. Local volatility (standard deviation of close prices in the match window)
  4. Pre-trend (close-to-close return over the 5 candles before the match)
  5. Up-candle ratio (fraction of `U` symbols in the match substring)
  6. Down-candle ratio (fraction of `D` symbols)
  7. Gap count (number of `G` symbols)
  8–11. Pattern category one-hot (bullish_continuation, bearish_continuation, reversal, gap_pattern)
- **Labeling:** Each match is labeled based on the 5-day forward return aligned with the pattern's expected direction. A bullish pattern match is labeled positive if the 5-day forward return is positive, and vice versa.
- **Training results:** 64 total match samples, 68.8% training accuracy. The model produces a probability score (0–1) for each match, which the Flutter app displays as a confidence percentage.

---

## Week 4 — Flutter App

**Goal:** Build a mobile/desktop front end to visualize the pipeline results.

**Completed:**

- **App architecture** (`flutter_app/`):
  - `lib/main.dart` — App entry point with dark Material3 theme
  - `lib/models/candle.dart` — CandleData model with OHLC fields and date
  - `lib/models/pattern_match.dart` — PatternMatch and PatternResult models
  - `lib/services/data_service.dart` — Loads `results.json` from the asset bundle
  - `lib/widgets/candlestick_chart.dart` — Custom-painted scrollable candlestick chart with price grid and pattern highlight overlays
  - `lib/widgets/pattern_card.dart` — Card showing pattern name, regex, match count, NFA/DFA cross-check status, average confidence bar, and automaton state counts
  - `lib/widgets/confidence_badge.dart` — Color-coded confidence badge (green ≥ 70%, amber ≥ 50%, red < 50%)
  - `lib/screens/home_screen.dart` — Home screen with the chart (top) and scrollable pattern list (bottom); tapping a pattern highlights its matches on the chart
- **Data flow:** The Python pipeline exports `output/results.json`, which is copied into `flutter_app/assets/`. The Flutter app loads this JSON at startup and renders the chart with all pattern data.
- **Interaction:** Tapping a pattern card toggles highlighting of that pattern's match spans on the candlestick chart. Bullish patterns highlight in teal, bearish in red.

---

## Week 5 — Documentation & Final Polish

**Goal:** Complete all documentation, generate final diagrams, and polish the deliverables.

**Completed:**

- **State diagrams:** 14 PNG images generated — NFA and minimized-DFA diagrams for all 7 regular patterns — in `output/diagrams/`.
- **Transition tables:** 7 CSV files and 7 human-readable TXT files for all minimized DFAs, in `output/transition_tables/`.
- **NFA/DFA cross-check:** All 7 regular patterns pass: every match found by the NFA is independently accepted by the minimized DFA, providing concrete proof of NFA/DFA language equivalence.
- **Output files:**
  - `output/results.md` — Markdown results table with all patterns, state counts, match counts, and cross-check status
  - `output/results.json` — Full JSON export for the Flutter app (candles, encoded string, pattern matches with confidence scores)
  - `output/candle_string.txt` — The encoded `{U,D,F,G}` string
  - `output/encoding_trace.csv` — Per-candle encoding breakdown
  - `output/match_summary.txt` — Human-readable match summary
- **README.md** — Complete project README with architecture diagram, pattern table, setup instructions, and demo results.
- **This progress report** — Final documentation of all five weeks.

---

## Demo Results (Real AAPL Data, 506 Candles)

| Pattern | Regex | NFA States | DFA States | Min-DFA States | Matches | Cross-Check |
|---|---|---|---|---|---|---|
| Three White Soldiers | `U{3,}` | 10 | 5 | 4 | 5 | PASS |
| Three Black Crows | `D{3,}` | 10 | 5 | 4 | 3 | PASS |
| Bullish Reversal | `D+FU+` | 14 | 6 | 4 | 2 | PASS |
| Bearish Reversal | `U+FD+` | 14 | 6 | 4 | 2 | PASS |
| Gap and Go | `GU+` | 8 | 4 | 3 | 37 | PASS |
| Exhaustion Gap | `U{2,}GD` | 12 | 6 | 5 | 1 | PASS |
| Indecision Cluster | `F{2,}` | 8 | 4 | 3 | 13 | PASS |
| Double Top | `U+DU+D` | — | — | — | 1 | Hybrid |

ML confidence model: 64 samples, 68.8% training accuracy.

---

## Conclusion

CandleLang demonstrates that candlestick pattern detection can be rigorously formulated as a formal language recognition problem. The hand-built regex → NFA → DFA → minimized-DFA pipeline proves understanding of regular languages and finite automata, the NFA/DFA cross-check provides concrete evidence of their equivalence, the Double Top hybrid pattern illustrates where regular languages reach their limits, and the ML confidence layer adds practical value by scoring each match against historical outcomes.
