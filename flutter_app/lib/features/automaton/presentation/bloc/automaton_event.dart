import 'package:equatable/equatable.dart';

import '../../../pattern_detection/domain/entities/pattern_definition.dart';

abstract class AutomatonEvent extends Equatable {
  const AutomatonEvent();

  @override
  List<Object?> get props => [];
}

/// Select a pre-defined candlestick pattern.
class SelectPatternRequested extends AutomatonEvent {
  final PatternDefinition pattern;
  const SelectPatternRequested(this.pattern);

  @override
  List<Object?> get props => [pattern];
}

/// Test a custom regex pattern.
class CustomRegexSubmitted extends AutomatonEvent {
  final String regex;
  const CustomRegexSubmitted(this.regex);

  @override
  List<Object?> get props => [regex];
}

/// Simulate a candidate string on current DFA.
class SimulateStringRequested extends AutomatonEvent {
  final String candidate;
  const SimulateStringRequested(this.candidate);

  @override
  List<Object?> get props => [candidate];
}
