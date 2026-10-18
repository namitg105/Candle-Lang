import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/run_full_analysis.dart';
import 'analysis_event.dart';
import 'analysis_state.dart';

/// BLoC that drives the visualization screen.
///
/// Receives [RunAnalysisRequested] → calls the use case →
/// emits [AnalysisLoading] then [AnalysisLoaded] or [AnalysisError].
class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  final RunFullAnalysis runFullAnalysis;

  AnalysisBloc({required this.runFullAnalysis})
      : super(const AnalysisInitial()) {
    on<RunAnalysisRequested>(_onRunAnalysis);
  }

  Future<void> _onRunAnalysis(
    RunAnalysisRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    emit(const AnalysisLoading());

    final result = await runFullAnalysis(const NoParams());

    result.fold(
      (failure) => emit(AnalysisError(failure.message)),
      (analysisResult) => emit(AnalysisLoaded(analysisResult)),
    );
  }
}
