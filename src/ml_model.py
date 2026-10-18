"""
ml_model.py
-----------
Lightweight ML confidence scoring for CandleLang pattern matches.

Implements a logistic regression classifier from scratch using only
numpy (no scikit-learn dependency), trained on forward returns after
each pattern match to answer: "when this pattern fires, how often
does the expected move actually follow?"

Pipeline:
    1. For each pattern match (start, end), compute the N-day forward
       return after the match ends.
    2. Extract features: match length, local volatility, trend
       strength, position in series, pattern one-hot encoding.
    3. Label: 1 if the forward return aligns with the pattern's
       expected direction (e.g. positive return after a bullish
       pattern), 0 otherwise.
    4. Train logistic regression via gradient descent.
    5. Output: a probability (confidence score) for each match.

This is a *demonstration* model for the MOC project, not production
trading advice.
"""

from __future__ import annotations
import math
from typing import Dict, List, Sequence, Tuple

from candle_encoder import Candle


# ── Feature extraction ──────────────────────────────────────────────

FORWARD_DAYS = 5  # look-ahead window for labelling

# Pattern expected direction: +1 = bullish, -1 = bearish, 0 = neutral
PATTERN_DIRECTION = {
    "three_white_soldiers": +1,
    "three_black_crows":    -1,
    "bullish_reversal":     +1,
    "bearish_reversal":     -1,
    "gap_and_go":           +1,
    "exhaustion_gap":       -1,
    "indecision_cluster":    0,
    "double_top":           -1,
}


def _safe_div(a: float, b: float) -> float:
    return a / b if b != 0 else 0.0


def extract_features(
    candles: Sequence[Candle],
    encoded: str,
    match_start: int,
    match_end: int,
    pattern_name: str,
    all_pattern_names: List[str],
) -> List[float]:
    """
    Extract a feature vector for one pattern match.

    Features (11 total):
      0. match_length        -- how many candle symbols the match spans
      1. relative_position   -- where in the series the match occurs (0..1)
      2. local_volatility    -- std dev of daily returns around the match
      3. pre_trend           -- average daily return in the 5 days before
      4. up_ratio            -- fraction of U's in the 10 chars before
      5. down_ratio          -- fraction of D's in the 10 chars before
      6. gap_count           -- number of G's in the 10 chars before
      7-10. pattern one-hot  -- which of the 4 pattern groups this is
            (bullish, bearish, neutral, hybrid)
    """
    n = len(encoded)
    features: List[float] = []

    # 0. match length (normalised by series length)
    match_len = match_end - match_start
    features.append(match_len / max(n, 1))

    # 1. relative position in the encoded string
    features.append(match_start / max(n - 1, 1))

    # 2. local volatility: std dev of daily returns in a window around the match
    # candles are offset by 1 from encoded (first candle has no encoded symbol)
    window_start = max(0, match_start - 5)
    window_end = min(len(candles) - 1, match_end + 5)
    returns = []
    for i in range(window_start + 1, window_end + 1):
        if i < len(candles) and candles[i - 1].close != 0:
            r = (candles[i].close - candles[i - 1].close) / candles[i - 1].close
            returns.append(r)
    if returns:
        mean_r = sum(returns) / len(returns)
        var = sum((r - mean_r) ** 2 for r in returns) / len(returns)
        features.append(math.sqrt(var))
    else:
        features.append(0.0)

    # 3. pre-trend: average return in 5 days before the match
    pre_returns = []
    for i in range(max(1, match_start - 4), match_start + 1):
        idx = i  # candle index offset
        if 0 < idx < len(candles) and candles[idx - 1].close != 0:
            r = (candles[idx].close - candles[idx - 1].close) / candles[idx - 1].close
            pre_returns.append(r)
    features.append(sum(pre_returns) / len(pre_returns) if pre_returns else 0.0)

    # 4-6. context character ratios (10 chars before)
    context = encoded[max(0, match_start - 10):match_start]
    ctx_len = max(len(context), 1)
    features.append(context.count("U") / ctx_len)
    features.append(context.count("D") / ctx_len)
    features.append(context.count("G") / ctx_len)

    # 7-10. pattern category one-hot
    direction = PATTERN_DIRECTION.get(pattern_name, 0)
    features.append(1.0 if direction == +1 else 0.0)  # bullish
    features.append(1.0 if direction == -1 else 0.0)  # bearish
    features.append(1.0 if direction ==  0 else 0.0)  # neutral
    features.append(1.0 if pattern_name == "double_top" else 0.0)  # hybrid

    return features


def compute_label(
    candles: Sequence[Candle],
    match_end: int,
    pattern_name: str,
    forward_days: int = FORWARD_DAYS,
) -> int:
    """
    Label = 1 if the forward return aligns with the pattern's expected
    direction:
      - bullish pattern: label=1 if forward return > 0
      - bearish pattern: label=1 if forward return < 0
      - neutral:         label=1 if abs(forward return) < 1%
    """
    # match_end is an index into the encoded string.
    # candle index = match_end (since encoded[i] corresponds to candle[i] roughly)
    # We want the return from candle[match_end] to candle[match_end + forward_days]
    candle_idx = min(match_end, len(candles) - 1)
    future_idx = min(candle_idx + forward_days, len(candles) - 1)

    if candle_idx >= len(candles) - 1 or candles[candle_idx].close == 0:
        return 0

    fwd_return = (
        (candles[future_idx].close - candles[candle_idx].close)
        / candles[candle_idx].close
    )

    direction = PATTERN_DIRECTION.get(pattern_name, 0)
    if direction == +1:
        return 1 if fwd_return > 0 else 0
    elif direction == -1:
        return 1 if fwd_return < 0 else 0
    else:
        return 1 if abs(fwd_return) < 0.01 else 0


# ── Logistic regression (pure numpy-free implementation) ────────────

def _sigmoid(z: float) -> float:
    """Numerically stable sigmoid."""
    if z >= 0:
        return 1.0 / (1.0 + math.exp(-z))
    else:
        ez = math.exp(z)
        return ez / (1.0 + ez)


def _dot(a: List[float], b: List[float]) -> float:
    return sum(x * y for x, y in zip(a, b))


class LogisticRegression:
    """
    Minimal logistic regression trained with gradient descent.
    No external dependencies -- pure Python + math.
    """

    def __init__(self, n_features: int, lr: float = 0.1, epochs: int = 200):
        self.weights = [0.0] * n_features
        self.bias = 0.0
        self.lr = lr
        self.epochs = epochs
        self.trained = False

    def predict_proba(self, x: List[float]) -> float:
        """Return P(y=1 | x)."""
        z = _dot(self.weights, x) + self.bias
        return _sigmoid(z)

    def fit(self, X: List[List[float]], y: List[int]):
        """Train on dataset X (list of feature vectors), y (list of 0/1 labels)."""
        n = len(X)
        if n == 0:
            return

        # normalise features (z-score)
        n_features = len(X[0])
        means = [0.0] * n_features
        stds = [1.0] * n_features

        for j in range(n_features):
            col = [X[i][j] for i in range(n)]
            m = sum(col) / n
            v = sum((x - m) ** 2 for x in col) / n
            means[j] = m
            stds[j] = math.sqrt(v) if v > 1e-12 else 1.0

        self._means = means
        self._stds = stds

        X_norm = [
            [(X[i][j] - means[j]) / stds[j] for j in range(n_features)]
            for i in range(n)
        ]

        # gradient descent
        self.weights = [0.0] * n_features
        self.bias = 0.0

        for epoch in range(self.epochs):
            dw = [0.0] * n_features
            db = 0.0
            total_loss = 0.0

            for i in range(n):
                p = self.predict_proba(X_norm[i])
                error = p - y[i]
                for j in range(n_features):
                    dw[j] += error * X_norm[i][j]
                db += error

                # log-loss for monitoring
                eps = 1e-15
                total_loss -= (
                    y[i] * math.log(max(p, eps))
                    + (1 - y[i]) * math.log(max(1 - p, eps))
                )

            for j in range(n_features):
                self.weights[j] -= self.lr * dw[j] / n
            self.bias -= self.lr * db / n

        self.trained = True

    def predict(self, x: List[float]) -> float:
        """Score a single feature vector (handles normalisation)."""
        if not self.trained:
            return 0.5  # uninformed prior
        x_norm = [
            (x[j] - self._means[j]) / self._stds[j]
            for j in range(len(x))
        ]
        return self.predict_proba(x_norm)


# ── High-level API ──────────────────────────────────────────────────

def build_dataset(
    candles: Sequence[Candle],
    encoded: str,
    all_matches: Dict[str, List[Tuple[int, int]]],
    all_pattern_names: List[str],
) -> Tuple[List[List[float]], List[int], List[dict]]:
    """
    Build the feature matrix and labels from all pattern matches.

    Returns (X, y, metadata) where metadata[i] records which pattern
    and match produced row i.
    """
    X: List[List[float]] = []
    y: List[int] = []
    meta: List[dict] = []

    for name, matches in all_matches.items():
        for start, end in matches:
            features = extract_features(
                candles, encoded, start, end, name, all_pattern_names
            )
            label = compute_label(candles, end, name)
            X.append(features)
            y.append(label)
            meta.append({"pattern": name, "start": start, "end": end})

    return X, y, meta


def train_and_score(
    candles: Sequence[Candle],
    encoded: str,
    all_matches: Dict[str, List[Tuple[int, int]]],
) -> Dict[str, List[Tuple[int, int, float]]]:
    """
    Train a logistic regression model on all pattern matches and return
    scored matches: {pattern_name: [(start, end, confidence), ...]}.

    The model is trained on the full dataset (this is a demonstration,
    not a backtest -- the point is to show the ML layer working within
    the MOC project, not to produce trading signals).
    """
    pattern_names = list(all_matches.keys())

    X, y, meta = build_dataset(candles, encoded, all_matches, pattern_names)

    if len(X) < 5:
        # too few samples to train meaningfully; return 0.5 for all
        result: Dict[str, List[Tuple[int, int, float]]] = {}
        for name, matches in all_matches.items():
            result[name] = [(s, e, 0.5) for s, e in matches]
        return result

    n_features = len(X[0])
    model = LogisticRegression(n_features=n_features, lr=0.05, epochs=300)
    model.fit(X, y)

    # compute accuracy on training set (for the report)
    correct = sum(
        1 for i in range(len(X))
        if (model.predict(X[i]) >= 0.5) == (y[i] == 1)
    )
    accuracy = correct / len(X)
    print(f"  ML model trained on {len(X)} samples, "
          f"training accuracy: {accuracy:.1%}")

    # score every match
    result: Dict[str, List[Tuple[int, int, float]]] = {}
    for i, m in enumerate(meta):
        name = m["pattern"]
        confidence = model.predict(X[i])
        if name not in result:
            result[name] = []
        result[name].append((m["start"], m["end"], round(confidence, 3)))

    return result


if __name__ == "__main__":
    print("ml_model.py: run via demo.py for the full pipeline.")
