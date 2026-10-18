import 'dart:math' as math;

import '../../../encoding/domain/entities/candle.dart';
import '../../../pattern_detection/domain/entities/pattern_definition.dart';
import '../../../pattern_detection/domain/entities/pattern_result.dart';
import '../../domain/entities/scored_match.dart';
import '../../domain/repositories/ml_repository.dart';

/// Pure-Dart logistic regression model for scoring pattern matches.
///
/// Unlike an inference-only model with fixed coefficients, this trains
/// a fresh model via gradient descent every time [trainAndScore] runs,
/// over every match found across all patterns for the current price
/// series. No external ML library is used — just the one algorithm the
/// Python prototype validated, carried over into Dart.
class MlRepositoryImpl implements MlRepository {
  static const int _numFeatures = 11;
  static const int _forwardHorizon = 5;
  static const double _neutralBand = 0.01; // ±1% treated as "stayed flat"

  @override
  Map<String, List<ScoredMatch>> trainAndScore({
    required List<PatternResult> patternResults,
    required String encodedString,
    required List<Candle> candles,
  }) {
    // ── Step 1: build one sample per match across every pattern ────────
    final samples = <_Sample>[];
    for (final result in patternResults) {
      for (final span in result.matches) {
        final features = _extractFeatures(
          encodedString: encodedString,
          matchStart: span.start,
          matchEnd: span.end,
          candles: candles,
          definition: result.definition,
        );
        final label = _computeLabel(
          direction: result.definition.direction,
          candles: candles,
          matchEnd: span.end,
        );
        samples.add(_Sample(
          patternName: result.definition.name,
          start: span.start,
          end: span.end,
          features: features,
          label: label,
        ));
      }
    }

    // ── Step 2: train on every sample whose forward-return label is
    //    known (i.e. there was enough future price history to compute
    //    a 5-day forward return) ──────────────────────────────────────
    final trainable = samples.where((s) => s.label != null).toList();
    final model = _LogisticRegression(numFeatures: _numFeatures);

    final labels = trainable.map((s) => s.label!).toSet();
    if (trainable.length >= 4 && labels.length > 1) {
      model.fit(
        trainable.map((s) => s.features).toList(),
        trainable.map((s) => s.label!).toList(),
      );
    }
    // Otherwise there isn't enough signal to train on (e.g. too few
    // matches, or every labeled match fell on the same side) — the
    // model keeps its zero-weight default, which predicts a neutral
    // 0.5 confidence for every match rather than a fabricated number.

    // ── Step 3: score every match (labeled or not) with the model ──────
    final result = <String, List<ScoredMatch>>{};
    for (final pr in patternResults) {
      result[pr.definition.name] = [];
    }
    for (final s in samples) {
      final confidence = model.predict(s.features);
      result[s.patternName]!.add(ScoredMatch(
        start: s.start,
        end: s.end,
        substring: encodedString.substring(s.start, s.end),
        confidence: confidence,
      ));
    }
    return result;
  }

  // ── Label: did the 5-day forward return agree with the pattern's
  //    expected direction? ─────────────────────────────────────────────
  int? _computeLabel({
    required PatternDirection direction,
    required List<Candle> candles,
    required int matchEnd,
  }) {
    final baseIndex = matchEnd - 1;
    final futureIndex = baseIndex + _forwardHorizon;
    if (baseIndex < 0 ||
        baseIndex >= candles.length ||
        futureIndex >= candles.length) {
      return null; // not enough future history to label this match
    }
    final baseClose = candles[baseIndex].close;
    if (baseClose == 0) return null;

    final forwardReturn = (candles[futureIndex].close - baseClose) / baseClose;

    switch (direction) {
      case PatternDirection.bullish:
        return forwardReturn > 0 ? 1 : 0;
      case PatternDirection.bearish:
        return forwardReturn < 0 ? 1 : 0;
      case PatternDirection.neutral:
        return forwardReturn.abs() < _neutralBand ? 1 : 0;
    }
  }

  // ── Feature extraction (11 features per match) ──────────────────────
  //
  //  0. match length, normalised by series length
  //  1. relative position in the series (0..1)
  //  2. local volatility — std dev of daily returns around the match
  //  3. pre-trend — average return over the 5 candles before the match
  //  4. up-candle ratio in the 10 characters before the match
  //  5. down-candle ratio in the 10 characters before the match
  //  6. gap-candle ratio in the 10 characters before the match
  //  7-9. pattern direction one-hot: bullish / bearish / neutral
  //  10. hybrid-pattern flag (double_top's numeric post-check)
  List<double> _extractFeatures({
    required String encodedString,
    required int matchStart,
    required int matchEnd,
    required List<Candle> candles,
    required PatternDefinition definition,
  }) {
    final n = encodedString.length;
    final features = <double>[];

    // 0. match length
    final matchLen = matchEnd - matchStart;
    features.add(matchLen / math.max(n, 1));

    // 1. relative position
    features.add(matchStart / math.max(n - 1, 1));

    // 2. local volatility
    final windowStart = math.max(0, matchStart - 5);
    final windowEnd = math.min(candles.length - 1, matchEnd + 5);
    final returns = <double>[];
    for (var i = windowStart + 1; i <= windowEnd; i++) {
      if (i < candles.length && candles[i - 1].close != 0) {
        returns.add(
          (candles[i].close - candles[i - 1].close) / candles[i - 1].close,
        );
      }
    }
    if (returns.isNotEmpty) {
      final meanR = returns.reduce((a, b) => a + b) / returns.length;
      final variance = returns
              .map((r) => (r - meanR) * (r - meanR))
              .reduce((a, b) => a + b) /
          returns.length;
      features.add(math.sqrt(variance));
    } else {
      features.add(0.0);
    }

    // 3. pre-trend
    final preReturns = <double>[];
    for (var i = math.max(1, matchStart - 4); i <= matchStart; i++) {
      if (i > 0 && i < candles.length && candles[i - 1].close != 0) {
        preReturns.add(
          (candles[i].close - candles[i - 1].close) / candles[i - 1].close,
        );
      }
    }
    features.add(preReturns.isEmpty
        ? 0.0
        : preReturns.reduce((a, b) => a + b) / preReturns.length);

    // 4-6. context character ratios (10 characters before the match)
    final ctxStart = math.max(0, matchStart - 10);
    final context = encodedString.substring(ctxStart, matchStart);
    final ctxLen = math.max(context.length, 1);
    features.add(context.split('').where((c) => c == 'U').length / ctxLen);
    features.add(context.split('').where((c) => c == 'D').length / ctxLen);
    features.add(context.split('').where((c) => c == 'G').length / ctxLen);

    // 7-10. pattern direction / hybrid one-hot — read directly from the
    // pattern's own definition, so this never drifts out of sync with
    // PatternDefinitionsSource.
    features.add(definition.isBullish ? 1.0 : 0.0);
    features.add(definition.isBearish ? 1.0 : 0.0);
    features.add(definition.direction == PatternDirection.neutral ? 1.0 : 0.0);
    features.add(definition.isHybrid ? 1.0 : 0.0);

    return features;
  }
}

/// One training/scoring sample: a match plus its feature vector and
/// (possibly unknown) training label.
class _Sample {
  final String patternName;
  final int start;
  final int end;
  final List<double> features;
  final int? label;

  _Sample({
    required this.patternName,
    required this.start,
    required this.end,
    required this.features,
    required this.label,
  });
}

/// Logistic regression trained from scratch via batch gradient descent,
/// with z-score feature normalisation computed from its own training set.
///
/// Mirrors the Python prototype's algorithm exactly — no external ML
/// library, no scikit-learn, no precomputed coefficients baked in.
class _LogisticRegression {
  final int numFeatures;

  late List<double> _weights;
  double _bias = 0.0;
  late List<double> _means;
  late List<double> _stds;

  _LogisticRegression({required this.numFeatures}) {
    _weights = List.filled(numFeatures, 0.0);
    _means = List.filled(numFeatures, 0.0);
    _stds = List.filled(numFeatures, 1.0);
  }

  void fit(
    List<List<double>> x,
    List<int> y, {
    double learningRate = 0.1,
    int iterations = 1000,
  }) {
    final n = x.length;
    if (n == 0) return;

    // z-score normalisation, computed from this training set.
    _means = List.generate(numFeatures, (j) {
      var sum = 0.0;
      for (final row in x) {
        sum += row[j];
      }
      return sum / n;
    });
    _stds = List.generate(numFeatures, (j) {
      final mean = _means[j];
      var sumSq = 0.0;
      for (final row in x) {
        final d = row[j] - mean;
        sumSq += d * d;
      }
      final std = math.sqrt(sumSq / n);
      return std < 1e-8 ? 1.0 : std;
    });

    final normalized = x
        .map((row) => List.generate(
              numFeatures,
              (j) => (row[j] - _means[j]) / _stds[j],
            ))
        .toList();

    _weights = List.filled(numFeatures, 0.0);
    _bias = 0.0;

    for (var iter = 0; iter < iterations; iter++) {
      final gradW = List.filled(numFeatures, 0.0);
      var gradB = 0.0;

      for (var i = 0; i < n; i++) {
        final z = _dot(normalized[i], _weights) + _bias;
        final pred = _sigmoid(z);
        final error = pred - y[i];
        for (var j = 0; j < numFeatures; j++) {
          gradW[j] += error * normalized[i][j];
        }
        gradB += error;
      }

      for (var j = 0; j < numFeatures; j++) {
        _weights[j] -= learningRate * gradW[j] / n;
      }
      _bias -= learningRate * gradB / n;
    }
  }

  double predict(List<double> features) {
    final normalized = List.generate(
      numFeatures,
      (j) => (features[j] - _means[j]) / _stds[j],
    );
    return _sigmoid(_dot(normalized, _weights) + _bias);
  }

  double _dot(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  /// Numerically stable sigmoid, safe for large |z|.
  double _sigmoid(double z) {
    if (z >= 0) {
      return 1.0 / (1.0 + math.exp(-z));
    } else {
      final ez = math.exp(z);
      return ez / (1.0 + ez);
    }
  }
}
