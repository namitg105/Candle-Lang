import 'package:equatable/equatable.dart';

import '../../domain/entities/analysis_result.dart';

/// States emitted by [AnalysisBloc].
abstract class AnalysisState extends Equatable {
  const AnalysisState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state before any analysis is triggered.
class AnalysisInitial extends AnalysisState {
  const AnalysisInitial();
}

/// Pipeline is running — show a loading indicator.
class AnalysisLoading extends AnalysisState {
  const AnalysisLoading();
}

/// Pipeline completed successfully — display the results.
class AnalysisLoaded extends AnalysisState {
  final AnalysisResult result;

  const AnalysisLoaded(this.result);

  @override
  List<Object?> get props => [result];
}

/// Pipeline failed — show the error message.
class AnalysisError extends AnalysisState {
  final String message;

  const AnalysisError(this.message);

  @override
  List<Object?> get props => [message];
}
