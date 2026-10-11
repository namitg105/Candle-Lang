"""
candle_encoder.py
------------------
Converts raw OHLC (Open, High, Low, Close) price data into a string over
the finite alphabet SIGMA = {U, D, F, G}:

    U (Up)   : close is meaningfully higher than open (bullish body)
    D (Down) : close is meaningfully lower than open (bearish body)
    F (Flat) : |close - open| is within a small threshold (doji-like/indecision)
    G (Gap)  : today's open gapped away from yesterday's close beyond a
               threshold (independent of what the body does afterwards)

This is the "data representation" layer of CandleLang: it turns a sequence
of real-valued prices into a finite string, which is what makes regular
languages / automata theory applicable to it at all.

Thresholds are expressed as a fraction of the previous close (e.g. 0.002 = 0.2%)
so the encoding is scale-invariant across stocks priced very differently.
"""

from dataclasses import dataclass
from typing import List, Sequence


@dataclass
class Candle:
    date: str
    open: float
    high: float
    low: float
    close: float


# The finite alphabet. Everything downstream (regex patterns, NFA, DFA)
# is built over exactly these four symbols.
ALPHABET = ("U", "D", "F", "G")


def encode_candles(
    candles: Sequence[Candle],
    body_threshold: float = 0.003,   # 0.3% of open -> body counts as U/D, else F
    gap_threshold: float = 0.005,    # 0.5% jump from prev close -> counts as gap
) -> str:
    """
    Encode a sequence of Candle objects into a string over {U, D, F, G}.

    Priority rule (documented, so matching is deterministic and total):
      1. If the candle opened with a gap beyond `gap_threshold` relative to
         the previous close, emit 'G' for that candle (the gap event is
         considered the dominant signal for that day).
      2. Otherwise classify the candle's own body:
         - body% >= +threshold  -> 'U'
         - body% <= -threshold  -> 'D'
         - otherwise            -> 'F'

    This keeps the encoding a *function* SIGMA_encode: Candles* -> {U,D,F,G}*,
    i.e. every price history maps to exactly one string, which is what lets
    us treat "has this stock ever shown pattern P" as a formal
    language-membership question.
    """
    out: List[str] = []
    prev_close = None

    for c in candles:
        symbol = None

        if prev_close is not None and prev_close != 0:
            gap_pct = (c.open - prev_close) / prev_close
            if abs(gap_pct) >= gap_threshold:
                symbol = "G"

        if symbol is None:
            if c.open == 0:
                symbol = "F"
            else:
                body_pct = (c.close - c.open) / c.open
                if body_pct >= body_threshold:
                    symbol = "U"
                elif body_pct <= -body_threshold:
                    symbol = "D"
                else:
                    symbol = "F"

        out.append(symbol)
        prev_close = c.close

    return "".join(out)


def encode_dataframe(df, body_threshold: float = 0.003, gap_threshold: float = 0.005) -> str:
    """
    Convenience wrapper: encode a pandas DataFrame with columns
    ['Open','High','Low','Close'] (case-insensitive) indexed by date.
    """
    cols = {c.lower(): c for c in df.columns}
    candles = []
    for idx, row in df.iterrows():
        candles.append(
            Candle(
                date=str(idx),
                open=float(row[cols["open"]]),
                high=float(row[cols["high"]]),
                low=float(row[cols["low"]]),
                close=float(row[cols["close"]]),
            )
        )
    return encode_candles(candles, body_threshold, gap_threshold)
