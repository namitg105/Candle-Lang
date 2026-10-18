import 'package:equatable/equatable.dart';

/// The confidence score from the ML model for a single pattern match.
class MlScore extends Equatable {
  /// Pattern name this score belongs to.
  final String patternName;

  /// Start index in the encoded string.
  final int matchStart;

  /// End index in the encoded string.
  final int matchEnd;

  /// Logistic regression probability (0.0–1.0).
  final double confidence;

  const MlScore({
    required this.patternName,
    required this.matchStart,
    required this.matchEnd,
    required this.confidence,
  });

  @override
  List<Object?> get props => [patternName, matchStart, matchEnd, confidence];
}
