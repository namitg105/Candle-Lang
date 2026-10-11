"""
synthetic_data.py
------------------
NOTE ON DATA: live market APIs (Yahoo Finance / NSE) are not reachable
from this sandboxed dev environment, and real historical-data collection
is scheduled as Week 3 work in the project plan anyway. For this
progress checkpoint we generate a realistic synthetic OHLC series
(geometric random walk with drift + volatility clustering + occasional
gap events) so the encoding/NFA/DFA pipeline can be demonstrated
end-to-end on data that *behaves* like a real stock. Every function here
will be swapped for a real data-fetch call (yfinance / NSE bhavcopy) in
Week 3 without touching any of the automaton code -- that's the payoff
of separating "get a candle string" from "operate on a candle string".
"""

import random
from candle_encoder import Candle


def generate_synthetic_candles(n=250, start_price=1000.0, seed=42):
    rng = random.Random(seed)
    candles = []
    price = start_price
    vol = 0.012  # base daily volatility, ~1.2%

    for i in range(n):
        # volatility clustering: occasionally enter a "choppy" regime
        if rng.random() < 0.03:
            vol = rng.uniform(0.01, 0.03)

        prev_close = price

        # occasional gap at the open
        gap = 0.0
        if rng.random() < 0.06:
            gap = rng.uniform(-0.02, 0.02)

        open_price = prev_close * (1 + gap)

        drift = 0.0004  # slight upward drift, like a real index over time
        shock = rng.gauss(drift, vol)
        close_price = open_price * (1 + shock)

        high = max(open_price, close_price) * (1 + abs(rng.gauss(0, vol / 3)))
        low = min(open_price, close_price) * (1 - abs(rng.gauss(0, vol / 3)))

        candles.append(
            Candle(
                date=f"Day{i+1:03d}",
                open=round(open_price, 2),
                high=round(high, 2),
                low=round(low, 2),
                close=round(close_price, 2),
            )
        )
        price = close_price

    return candles
