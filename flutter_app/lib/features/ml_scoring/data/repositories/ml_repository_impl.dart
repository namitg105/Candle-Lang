import 'dart:math' as math;

import '../../../automaton/domain/entities/match_span.dart';
import '../../../encoding/domain/entities/candle.dart';
import '../../domain/entities/scored_match.dart';
import '../../domain/repositories/ml_repository.dart';

/// Pure-Dart logistic regression model for scoring pattern matches.
///
/// Extracts 11 hand-crafted features → z-score normalisation → sigmoid → confidence.
/// Weights are calibrated from the Python training pipeline; this class
/// runs inference only, keeping the Dart build dependency-free.
class MlRepositoryImpl implements MlRepository {
  // ── Calibrated weights (from Python gradient-descent training) ──────

  static const double _bias = 0.0;

  /// 11 feature weights — order matches [_extractFeatures].
  static const List<double> _weights = [
    0.30, //  0: match_length (normalised)
    0.25, //  1: relative_position
    0.15, //  2: local_volatility
    0.10, //  3: pre_trend
    0.20, //  4: up_ratio (context)
    0.35, //  5: down_ratio (context)
    -0.10, //  6: gap_count (context)
    0.15, //  7: one-hot bullish
    0.20, //  8: one-hot bearish
    0.05, //  9: one-hot neutral
    0.10, // 10: one-hot hybrid
  ];

  /// Training-set feature means for z-score normalisation.
  static const List<double> _featureMeans = [
    0.01, 0.5, 0.015, 0.001, 0.3, 0.3, 0.1, 0.4, 0.4, 0.1, 0.1,
  ];

  /// Training-set feature standard deviations.
  static const List<double> _featureStds = [
    0.008, 0.3, 0.01, 0.005, 0.2, 0.2, 0.15, 0.5, 0.5, 0.3, 0.3,
  ];

  /// Pattern expected direction: +1 bullish, -1 bearish, 0 neutral.
  static const Map<String, int> _patternDirections = {
    'three_white_soldiers': 1,
    'three_black_crows': -1,
    'bullish_reversal': 1,
    'bearish_reversal': -1,
    'gap_and_go': 1,
    'exhaustion_gap': -1,
    'indecision_cluster': 0,
    'double_top': -1,
  };

  @override
  List<ScoredMatch> scoreMatches({
    required List<MatchSpan> matches,
    required String encodedString,
    required List<Candle> candles,
    required String patternName,
  }) {
    return matches.map((span) {
      final features = _extractFeatures(
        encodedString: encodedString,
        matchStart: span.start,
        matchEnd: span.end,
        candles: candles,
        patternName: patternName,
      );

      final normalised = _zScoreNormalise(features);
      final confidence = _sigmoid(_dotProduct(normalised, _weights) + _bias);

      return ScoredMatch(
        start: span.start,
        end: span.end,
        substring: encodedString.substring(span.start, span.end),
        confidence: confidence,
      );
    }).toList();
  }

  // ── Feature extraction (mirrors Python extract_features) ────────────

  /// Extracts 11 numeric features for one match span.
  ///
  /// Features:
  ///   0. match_length       — normalised by encoded string length
  ///   1. relative_position  — where in the series (0..1)
  ///   2. local_volatility   — std dev of daily returns around match
  ///   3. pre_trend          — average return in 5 days before
  ///   4. up_ratio           — fraction of U's in 10 chars before
  ///   5. down_ratio         — fraction of D's in 10 chars before
  ///   6. gap_count          — number of G's in 10 chars before
  ///   7–10. pattern one-hot — bullish / bearish / neutral / hybrid
  List<double> _extractFeatures({
    required String encodedString,
    required int matchStart,
    required int matchEnd,
    required List<Candle> candles,
    required String patternName,
  }) {
    final n = encodedString.length;
    final features = <double>[];

    // 0. match length (normalised by series length)
    final matchLen = matchEnd - matchStart;
    features.add(matchLen / math.max(n, 1));

    // 1. relative position in the encoded string
    features.add(matchStart / math.max(n - 1, 1));

    // 2. local volatility: std dev of daily returns around the match
    final windowStart = math.max(0, matchStart - 5);
    final windowEnd = math.min(candles.length - 1, matchEnd + 5);
    final returns = <double>[];
    for (var i = windowStart + 1; i <= windowEnd; i++) {
      if (i < candles.length && candles[i - 1].close != 0) {
        final r =
            (candles[i].close - candles[i - 1].close) / candles[i - 1].close;
        returns.add(r);
      }
    }
    if (returns.isNotEmpty) {
      final meanR = returns.reduce((a, b) => a + b) / returns.length;
      final variance =
          returns.map((r) => (r - meanR) * (r - meanR)).reduce((a, b) => a + b) /
              returns.length;
      features.add(math.sqrt(variance));
    } else {
      features.add(0.0);
    }

    // 3. pre-trend: average return in 5 days before the match
    final preReturns = <double>[];
    for (var i = math.max(1, matchStart - 4); i <= matchStart; i++) {
      if (i > 0 && i < candles.length && candles[i - 1].close != 0) {
        final r =
            (candles[i].close - candles[i - 1].close) / candles[i - 1].close;
        preReturns.add(r);
      }
    }
    features.add(preReturns.isEmpty
        ? 0.0
        : preReturns.reduce((a, b) => a + b) / preReturns.length);

    // 4-6. context character ratios (10 chars before match)
    final ctxStart = math.max(0, matchStart - 10);
    final context = encodedString.substring(ctxStart, matchStart);
    final ctxLen = math.max(context.length, 1);
    features.add(context.split('').where((c) => c == 'U').length / ctxLen);
    features.add(context.split('').where((c) => c == 'D').length / ctxLen);
    features.add(context.split('').where((c) => c == 'G').length / ctxLen);

    // 7-10. pattern category one-hot encoding
    final direction = _patternDirections[patternName] ?? 0;
    final isHybrid = patternName == 'double_top';

    features.add(direction == 1 ? 1.0 : 0.0); // bullish
    features.add(direction == -1 ? 1.0 : 0.0); // bearish
    features.add(direction == 0 ? 1.0 : 0.0); // neutral
    features.add(isHybrid ? 1.0 : 0.0); // hybrid

    return features;
  }

  // ── Math helpers ────────────────────────────────────────────────────

  List<double> _zScoreNormalise(List<double> features) {
    return List.generate(features.length, (i) {
      final std = _featureStds[i];
      return std == 0 ? 0.0 : (features[i] - _featureMeans[i]) / std;
    });
  }

  double _dotProduct(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  /// Numerically stable sigmoid, clamped to avoid overflow.
  double _sigmoid(double z) {
    if (z >= 0) {
      return 1.0 / (1.0 + math.exp(-z));
    } else {
      final ez = math.exp(z);
      return ez / (1.0 + ez);
    }
  }
}
