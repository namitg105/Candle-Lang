# CandleLang — Full Pipeline Results (Real Data)

**Source:** https://raw.githubusercontent.com/plotly/datasets/master/finance-charts-apple.csv

**Symbol:** AAPL | **Range:** 2015-02-17 to 2017-02-16 | 506 candles -> 506 encoded symbols

## Pattern Matching Results

| Pattern | Regex | NFA states | DFA states | Min DFA states | Occurrences | NFA/DFA cross-check |
|---|---|---|---|---|---|---|
| three_white_soldiers | `U{3,}` | 10 | 5 | 4 | 5 | PASS |
| three_black_crows | `D{3,}` | 10 | 5 | 4 | 3 | PASS |
| bullish_reversal | `D+FU+` | 14 | 6 | 4 | 2 | PASS |
| bearish_reversal | `U+FD+` | 14 | 6 | 4 | 2 | PASS |
| gap_and_go | `GU+` | 8 | 4 | 3 | 37 | PASS |
| exhaustion_gap | `U{2,}GD` | 12 | 6 | 5 | 1 | PASS |
| indecision_cluster | `F{2,}` | 8 | 4 | 3 | 13 | PASS |
| double_top | `U+DU+D` | - | - | - | 1 | regex + numeric peak check |

## ML Confidence Scores (sample)

| Pattern | Match | Substring | Confidence |
|---|---|---|---|
| three_white_soldiers | [290:293] | `UUU` | 0.479 |
| three_white_soldiers | [345:348] | `UUU` | 0.698 |
| three_white_soldiers | [371:374] | `UUU` | 0.718 |
| three_black_crows | [200:203] | `DDD` | 0.268 |
| three_black_crows | [306:309] | `DDD` | 0.316 |
| three_black_crows | [360:363] | `DDD` | 0.205 |
| bullish_reversal | [34:38] | `DFUU` | 0.751 |
| bullish_reversal | [64:68] | `DFUU` | 0.575 |
| bearish_reversal | [193:196] | `UFD` | 0.383 |
| bearish_reversal | [357:363] | `UUFDDD` | 0.504 |
| gap_and_go | [9:11] | `GU` | 0.295 |
| gap_and_go | [20:22] | `GU` | 0.414 |
| gap_and_go | [55:57] | `GU` | 0.391 |
| exhaustion_gap | [36:40] | `UUGD` | 0.485 |
| indecision_cluster | [40:42] | `FF` | 0.147 |
| indecision_cluster | [112:114] | `FF` | 0.077 |
| indecision_cluster | [259:261] | `FF` | 0.097 |
| double_top | [83:87] | `UDUD` | 0.929 |
