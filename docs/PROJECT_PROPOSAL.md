# Models of Computation – Course Project Proposal

**BCSE302L / BACSE202 — Models of Computation**
Vellore Institute of Technology

## CandleLang: A Formal Regular-Language Engine for Candlestick Pattern Detection with ML-Based Confidence Scoring

| Field | Detail |
|---|---|
| Student Name | Namit Gupta |
| Registration Number | 25BDE0068 |
| Team Size | 1 (Individual Project) |
| School / Campus | VIT Vellore |
| Course | Models of Computation |
| Date of Submission | 03 August 2026 |

## Abstract

Technical analysts identify recurring candlestick patterns (e.g. Three White Soldiers, Double Top, Bullish Engulfing) in stock price charts to anticipate short-term price movement. Existing charting platforms detect these patterns using hardcoded, non-transparent rule engines, and general-purpose text tools such as Python's `re` module treat pattern matching as a black box that hides the underlying automaton entirely.

This project, CandleLang, reframes candlestick pattern detection as a formal language recognition problem. Each candle in a stock's price history is mapped to a symbol over a finite alphabet (e.g. U = up, D = down, F = flat, G = gap-up), converting price history into a string. Known technical patterns are then expressed as regular expressions over this alphabet, and a complete regex-to-NFA-to-DFA pipeline is implemented from first principles using Thompson's Construction, Subset Construction, and DFA Minimization, rather than relying on any existing regex library.

Every DFA-detected pattern match is subsequently passed through a lightweight machine learning classifier trained on historical price data, which assigns a data-driven confidence score reflecting how reliably that pattern has historically preceded its expected price movement. The complete system is delivered as a cross-platform Flutter application that fetches live OHLC (Open-High-Low-Close) market data, renders interactive candlestick charts, visually highlights DFA-detected pattern matches, and displays the corresponding ML confidence score, giving retail traders an explainable, formally verifiable alternative to opaque commercial pattern-detection tools.

## Objectives

- To formally model candlestick price-action sequences as strings over a finite alphabet, establishing a rigorous mapping between real market data and formal language models.
- To design regular expressions for at least 6–8 well-known technical trading patterns and implement Thompson's Construction to convert each regex into an equivalent NFA.
- To implement Subset Construction to convert the constructed NFAs into DFAs, and apply DFA Minimization to obtain the smallest equivalent automaton for each pattern.
- To build a from-scratch automaton simulation engine (no external regex library) capable of scanning real, live candlestick sequences and reporting exact match positions and states.
- To train and integrate a lightweight machine learning classifier that scores the historical reliability of each DFA-detected pattern using labeled historical OHLC data.
- To develop a Flutter-based mobile/cross-platform application that fetches real market data, renders candlestick charts, and visually surfaces both the automaton's matches and the ML confidence score.
- To document and visually present the internal NFA/DFA state diagrams for each pattern, making the system fully explainable and formally verifiable — unlike existing black-box charting tools.

## Expected Outcomes

- A working, from-scratch regex-to-NFA-to-DFA engine, with formal proof/demonstration of correctness and minimization for each implemented pattern, directly demonstrating mastery of Modules 1 and 2 of the Models of Computation syllabus (regular expressions, NFA, DFA, minimization).
- A functional cross-platform Flutter application capable of pulling live/historical stock data, rendering candlestick charts, and highlighting automaton-detected patterns in real time.
- A trained ML confidence-scoring layer that quantifies the historical reliability of each detected pattern, moving beyond simple pattern-matching to data-backed insight.
- A documented, reproducible pipeline (regex → NFA → DFA → minimized DFA → live detection) suitable for inclusion in a technical portfolio, GitHub repository, and LinkedIn showcase as evidence of applied theoretical computer science.
- A practical, explainable decision-support tool for retail traders that is transparent about why a pattern was flagged and how reliable it has historically been — an explainability advantage over existing commercial charting tools.

---
*A Word version of this proposal is also included: [`CandleLang_Project_Proposal.docx`](CandleLang_Project_Proposal.docx).*
