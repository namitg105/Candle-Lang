import 'package:equatable/equatable.dart';

import '../../domain/entities/automaton_inspection.dart';
import '../../domain/entities/match_span.dart';

abstract class AutomatonState extends Equatable {
  const AutomatonState();

  @override
  List<Object?> get props => [];
}

class AutomatonInitial extends AutomatonState {
  const AutomatonInitial();
}

class AutomatonLoading extends AutomatonState {
  const AutomatonLoading();
}

/// Sentinel used by [AutomatonLoaded.copyWith] to distinguish "field not
/// passed" from "field explicitly passed as null" — a plain `value ?? old`
/// copyWith can never null out [AutomatonLoaded.traceResult], which is
/// exactly what clearing the simulator input needs to do.
const Object _unset = Object();

class AutomatonLoaded extends AutomatonState {
  final String patternName;
  final String patternRegex;
  final String? meaning;
  final AutomatonInspection inspection;
  final String candidateString;

  /// Answers "does the WHOLE candidate string belong to this pattern?"
  /// (full-string DFA acceptance).
  final DfaTraceResult? traceResult;

  /// Answers "does this pattern occur ANYWHERE inside the candidate
  /// string?" (substring search over the NFA) -- the same check Market
  /// Chart runs when scanning candle data. Kept alongside [traceResult]
  /// so the UI can show both answers instead of just one.
  final List<MatchSpan>? substringMatches;

  const AutomatonLoaded({
    required this.patternName,
    required this.patternRegex,
    this.meaning,
    required this.inspection,
    this.candidateString = '',
    this.traceResult,
    this.substringMatches,
  });

  AutomatonLoaded copyWith({
    String? patternName,
    String? patternRegex,
    String? meaning,
    AutomatonInspection? inspection,
    String? candidateString,
    Object? traceResult = _unset,
    Object? substringMatches = _unset,
  }) {
    return AutomatonLoaded(
      patternName: patternName ?? this.patternName,
      patternRegex: patternRegex ?? this.patternRegex,
      meaning: meaning ?? this.meaning,
      inspection: inspection ?? this.inspection,
      candidateString: candidateString ?? this.candidateString,
      traceResult: identical(traceResult, _unset)
          ? this.traceResult
          : traceResult as DfaTraceResult?,
      substringMatches: identical(substringMatches, _unset)
          ? this.substringMatches
          : substringMatches as List<MatchSpan>?,
    );
  }

  @override
  List<Object?> get props => [
        patternName,
        patternRegex,
        meaning,
        inspection,
        candidateString,
        traceResult,
        substringMatches,
      ];
}

class AutomatonError extends AutomatonState {
  final String message;
  const AutomatonError(this.message);

  @override
  List<Object?> get props => [message];
}
