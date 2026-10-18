import 'package:equatable/equatable.dart';

/// Events that trigger analysis pipeline actions.
abstract class AnalysisEvent extends Equatable {
  const AnalysisEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers the full CandleLang analysis pipeline.
class RunAnalysisRequested extends AnalysisEvent {
  const RunAnalysisRequested();
}
