import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/match_span.dart';
import '../../domain/usecases/inspect_automaton.dart';
import '../../domain/usecases/search_nfa.dart';
import 'automaton_event.dart';
import 'automaton_state.dart';

/// Manages state for formal automata inspection and interactive simulation.
class AutomatonBloc extends Bloc<AutomatonEvent, AutomatonState> {
  final InspectAutomaton inspectAutomaton;
  final SearchNfa searchNfa;

  AutomatonBloc({required this.inspectAutomaton, required this.searchNfa})
      : super(const AutomatonInitial()) {
    on<SelectPatternRequested>(_onSelectPattern);
    on<CustomRegexSubmitted>(_onCustomRegexSubmitted);
    on<SimulateStringRequested>(_onSimulateString);
  }

  Future<void> _onSelectPattern(
    SelectPatternRequested event,
    Emitter<AutomatonState> emit,
  ) async {
    final regex = event.pattern.regex;
    if (regex == null || regex.isEmpty) {
      emit(const AutomatonError('Pattern does not define a regular expression'));
      return;
    }

    emit(const AutomatonLoading());
    final failureOrInspection = await inspectAutomaton(
      InspectAutomatonParams(regex),
    );

    failureOrInspection.fold(
      (failure) => emit(AutomatonError(failure.message)),
      (inspection) => emit(AutomatonLoaded(
        patternName: event.pattern.displayName,
        patternRegex: regex,
        meaning: event.pattern.meaning,
        inspection: inspection,
      )),
    );
  }

  Future<void> _onCustomRegexSubmitted(
    CustomRegexSubmitted event,
    Emitter<AutomatonState> emit,
  ) async {
    if (event.regex.trim().isEmpty) return;
    emit(const AutomatonLoading());

    final failureOrInspection = await inspectAutomaton(
      InspectAutomatonParams(event.regex.trim()),
    );

    failureOrInspection.fold(
      (failure) => emit(AutomatonError(failure.message)),
      (inspection) => emit(AutomatonLoaded(
        patternName: 'Custom Regex',
        patternRegex: event.regex.trim(),
        meaning: 'User-defined regular expression over {U, D, F, G}',
        inspection: inspection,
      )),
    );
  }

  Future<void> _onSimulateString(
    SimulateStringRequested event,
    Emitter<AutomatonState> emit,
  ) async {
    if (state is! AutomatonLoaded) return;
    final current = state as AutomatonLoaded;

    final trimmed = event.candidate.trim().toUpperCase();
    if (trimmed.isEmpty) {
      emit(current.copyWith(
        candidateString: '',
        traceResult: null,
        substringMatches: null,
      ));
      return;
    }

    // Question 1: does the ENTIRE string, start to finish, belong to this
    // pattern's language? This is standard DFA acceptance (δ*) -- the same
    // thing a regex engine's `^pattern$` would check.
    final trace = current.inspection.simulate(trimmed);

    // Question 2: does the pattern occur ANYWHERE inside this string, even
    // as part of something longer? This is a substring/"grep" search over
    // the NFA -- and it's exactly what the Market Chart screen uses when
    // it scans 120 candles of encoded data for a pattern. Running both
    // here keeps this page's answer consistent with what Market Chart
    // reports for the same data, instead of only answering Question 1.
    final failureOrMatches = await searchNfa(
      SearchNfaParams(nfa: current.inspection.nfa, text: trimmed),
    );
    final matches = failureOrMatches.fold(
      (failure) => const <MatchSpan>[],
      (matches) => matches,
    );

    emit(current.copyWith(
      candidateString: trimmed,
      traceResult: trace,
      substringMatches: matches,
    ));
  }
}
