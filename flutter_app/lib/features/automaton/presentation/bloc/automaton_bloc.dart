import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/inspect_automaton.dart';
import 'automaton_event.dart';
import 'automaton_state.dart';

/// Manages state for formal automata inspection and interactive simulation.
class AutomatonBloc extends Bloc<AutomatonEvent, AutomatonState> {
  final InspectAutomaton inspectAutomaton;

  AutomatonBloc({required this.inspectAutomaton})
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

  void _onSimulateString(
    SimulateStringRequested event,
    Emitter<AutomatonState> emit,
  ) {
    if (state is! AutomatonLoaded) return;
    final current = state as AutomatonLoaded;

    final trimmed = event.candidate.trim().toUpperCase();
    if (trimmed.isEmpty) {
      emit(current.copyWith(candidateString: '', traceResult: null));
      return;
    }

    final trace = current.inspection.simulate(trimmed);
    emit(current.copyWith(
      candidateString: trimmed,
      traceResult: trace,
    ));
  }
}
