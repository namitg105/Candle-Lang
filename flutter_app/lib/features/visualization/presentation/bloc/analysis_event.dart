import 'package:equatable/equatable.dart';

import '../../../../core/constants/supported_symbols.dart';

/// Events that trigger analysis pipeline actions.
abstract class AnalysisEvent extends Equatable {
  const AnalysisEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers the full CandleLang analysis pipeline for [symbol].
class RunAnalysisRequested extends AnalysisEvent {
  final String symbol;

  const RunAnalysisRequested({
    this.symbol = SupportedSymbols.defaultSymbol,
  });

  @override
  List<Object?> get props => [symbol];
}
