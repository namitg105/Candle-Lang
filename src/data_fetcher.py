"""
data_fetcher.py
----------------
Downloads real, internet-sourced historical OHLC data and returns it as
a list of Candle objects compatible with candle_encoder.py.

Primary source: a publicly hosted real AAPL daily-OHLC CSV on GitHub
(Plotly's official sample dataset -- genuine exchange-recorded prices,
~500 trading days, Feb 2015 – Feb 2017).

Also includes fetch_live_yahoo() which works on an unrestricted network
(it calls Yahoo Finance's public chart API). Inside a sandboxed
environment that blocks most finance APIs, the GitHub dataset is used
instead.

If neither network source is reachable, falls back to the synthetic
data generator in synthetic_data.py so the demo always runs.
"""

from __future__ import annotations
import csv
import io
import json
import urllib.request
from typing import List

from candle_encoder import Candle

# ── Primary source: real AAPL data on GitHub ─────────────────────────
DEFAULT_DATA_URL = (
    "https://raw.githubusercontent.com/plotly/datasets/master/"
    "finance-charts-apple.csv"
)
DEFAULT_SYMBOL = "AAPL"


def _http_get(url: str, timeout: int = 20) -> str:
    """Simple GET request with a sensible User-Agent."""
    req = urllib.request.Request(url, headers={"User-Agent": "CandleLang/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read().decode("utf-8")


def fetch_real_ohlc(url: str = DEFAULT_DATA_URL) -> List[Candle]:
    """
    Download a real historical OHLC CSV from the internet and parse it
    into a chronologically-ordered list of Candle objects.

    Column names are matched loosely by suffix (e.g. "AAPL.Open",
    "Open", "open") so this works across differently-prefixed CSVs
    from the same family of datasets.
    """
    raw = _http_get(url)
    reader = csv.DictReader(io.StringIO(raw))
    fieldnames = reader.fieldnames or []

    def find_col(suffix: str) -> str:
        for f in fieldnames:
            if f.lower().endswith(suffix):
                return f
        raise KeyError(
            f"Could not find a column ending in '{suffix}' "
            f"in {fieldnames}"
        )

    date_col = find_col("date")
    open_col = find_col("open")
    high_col = find_col("high")
    low_col  = find_col("low")
    close_col = find_col("close")

    candles: List[Candle] = []
    for row in reader:
        candles.append(Candle(
            date=row[date_col],
            open=float(row[open_col]),
            high=float(row[high_col]),
            low=float(row[low_col]),
            close=float(row[close_col]),
        ))

    # the sample dataset is already chronological, but sort defensively
    candles.sort(key=lambda c: c.date)
    return candles


def fetch_live_yahoo(
    symbol: str = DEFAULT_SYMBOL,
    range_: str = "1y",
    interval: str = "1d",
) -> List[Candle]:
    """
    True LIVE data via Yahoo Finance's public chart API.  This is
    network-blocked inside sandboxed environments, but works unmodified
    on an unrestricted machine -- swap this in for fetch_real_ohlc()
    to get genuinely live, up-to-the-minute data.
    """
    url = (
        f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}"
        f"?range={range_}&interval={interval}"
    )
    raw = _http_get(url)
    data = json.loads(raw)
    result = data["chart"]["result"][0]
    timestamps = result["timestamp"]
    quote = result["indicators"]["quote"][0]

    candles: List[Candle] = []
    for i, ts in enumerate(timestamps):
        o = quote["open"][i]
        h = quote["high"][i]
        l = quote["low"][i]
        c = quote["close"][i]
        if None in (o, h, l, c):
            continue  # Yahoo sometimes returns nulls for holidays
        date_str = (
            __import__("datetime")
            .datetime.utcfromtimestamp(ts)
            .strftime("%Y-%m-%d")
        )
        candles.append(Candle(date=date_str, open=o, high=h, low=l, close=c))
    return candles


def fetch_candles(prefer_live: bool = False) -> List[Candle]:
    """
    Convenience function: tries the best available data source and
    falls back gracefully.

    Order:
      1. If prefer_live: try Yahoo Finance first (works on unrestricted
         networks only).
      2. Try the GitHub-hosted real CSV (works in most environments).
      3. Fall back to synthetic data (always works, no network needed).
    """
    if prefer_live:
        try:
            candles = fetch_live_yahoo()
            if candles:
                print(f"[data_fetcher] Live Yahoo data: {len(candles)} candles")
                return candles
        except Exception as e:
            print(f"[data_fetcher] Yahoo unavailable ({e}), trying GitHub CSV...")

    try:
        candles = fetch_real_ohlc()
        if candles:
            print(f"[data_fetcher] Real GitHub CSV: {len(candles)} candles "
                  f"({candles[0].date} -> {candles[-1].date})")
            return candles
    except Exception as e:
        print(f"[data_fetcher] GitHub CSV unavailable ({e}), using synthetic data...")

    from synthetic_data import generate_synthetic_candles
    candles = generate_synthetic_candles(n=500)
    print(f"[data_fetcher] Synthetic fallback: {len(candles)} candles")
    return candles


if __name__ == "__main__":
    candles = fetch_candles()
    print(f"Fetched {len(candles)} candles")
    print("First 3:", candles[:3])
    print("Last 3:",  candles[-3:])
