# CandleLang

**A formal regular-language engine for candlestick pattern detection with ML-based confidence scoring, built entirely in pure Dart and Flutter from first principles — regex → NFA (Thompson's Construction) → DFA (Subset Construction) → minimized DFA (Moore's algorithm) — following 3-Layer Clean Architecture with zero external backend or Python dependencies.**

> Models of Computation (BCSE302L / BACSE202) course project — Vellore Institute of Technology  
> Namit Gupta · Reg. No. 25BDE0068

---

## The Idea

CandleLang reframes technical candlestick pattern detection as a **formal language recognition problem**:

1. **Finite Alphabet Encoding**: Every candle in a stock's price history is mapped to a symbol over a 4-letter alphabet $\Sigma = \{U, D, F, G\}$ ($U$ = Up, $D$ = Down, $F$ = Flat, $G$ = Gap), converting price history into a formal word.
2. **Patterns as Regular Expressions**: Known trading patterns are defined as regular expressions (e.g. Three White Soldiers = `U{3,}`, Bullish Reversal = `D+FU+`).
3. **Automata from First Principles (100% Pure Dart)**:
   - **Thompson's Construction**: Regex AST $\rightarrow$ $\epsilon$-NFA with inductive state transitions.
   - **Subset Construction**: $\epsilon$-NFA $\rightarrow$ DFA via $\epsilon$-closure and powerset state mapping.
   - **DFA Minimization**: Moore's partition refinement algorithm to compute the minimal equivalent automaton.
4. **Lightweight ML Scoring**: Pure Dart logistic regression classifier calculating data-backed historical confidence percentages.
5. **Interactive Flutter UI**:
   - **Market Chart**: Candlestick chart with dynamic glowing pattern highlight overlays.
   - **Automata Theory Inspector**: Interactive screen showing AST tree, state reduction metrics (NFA vs DFA vs MinDFA), full DFA transition matrix ($\delta: Q \times \Sigma \rightarrow Q$), and interactive string simulation.
   - **Encoding Trace**: Per-candle price movement trace table explaining each symbol assignment.

---

## 100% Pure Dart Clean Architecture

The application has **zero Python dependencies** and requires **no external backend server**. Everything is built in Dart following Clean Architecture:

```text
flutter_app/lib/
├── core/                           # Shared error types, theme, base use cases
└── features/
    ├── encoding/                   # OHLC Data fetch (remote CDN + offline asset) & {U,D,F,G} encoder
    │   ├── data/                   # CandleRemoteDataSource, CandleLocalDataSource, CandleModel
    │   ├── domain/                 # Candle entity, EncodingRepository, FetchCandleData, EncodeCandles
    │   └── presentation/           # EncodingBloc, EncodingPage, EncodingTraceTable
    ├── automaton/                  # Formal language engine
    │   ├── data/                   # AutomatonRepositoryImpl (Thompson, Subset, Moore, parser)
    │   ├── domain/                 # NFA, DFA, RegexNode, AutomatonInspection, InspectAutomaton
    │   └── presentation/           # AutomatonBloc, AutomatonPage, DfaTransitionTable, StateReductionCard
    ├── pattern_detection/          # Technical pattern detection rules
    │   ├── data/                   # PatternDefinitionsSource, PatternRepositoryImpl
    │   └── domain/                 # PatternDefinition, PatternResult, DetectAllPatterns, DetectDoubleTop
    ├── ml_scoring/                 # Machine learning confidence inference
    │   ├── data/                   # MlRepositoryImpl (11-feature extraction, z-score, sigmoid)
    │   └── domain/                 # MlScore, ScoredMatch, ScoreMatches use case
    └── visualization/              # UI visualization shell
        ├── data/                   # AnalysisRepositoryImpl
        ├── domain/                 # AnalysisResult, RunFullAnalysis
        └── presentation/           # AnalysisBloc, HomePage, CandlestickChart, PatternCard
```

---

## Patterns Implemented

| Pattern | Regex | Type | Meaning |
|---|---|---|---|
| Three White Soldiers | `U{3,}` | Regular | 3+ consecutive bullish candles — strong buying momentum |
| Three Black Crows | `D{3,}` | Regular | 3+ consecutive bearish candles — strong selling pressure |
| Bullish Reversal | `D+FU+` | Regular | Downtrend, doji pause, then upside resume |
| Bearish Reversal | `U+FD+` | Regular | Uptrend, doji pause, then downside resume |
| Gap and Go | `GU+` | Regular | Gap open followed by bullish continuation |
| Exhaustion Gap | `U{2,}GD` | Regular | Bullish run, gap up, then bearish reversal |
| Indecision Cluster | `F{2,}` | Regular | 2+ flat/doji candles — market indecision |
| Double Top | `U+DU+D` | **Hybrid** | Regular shape pre-filter + numeric peak-height verification |

---

## Running the Application

Only the Flutter SDK is required:

```bash
cd flutter_app

# Fetch dependencies
flutter pub get

# Run automated tests
flutter test

# Run on Chrome
flutter run -d chrome

# Or run on Windows Desktop
flutter run -d windows
```

---

## License

MIT — see [`LICENSE`](LICENSE).
