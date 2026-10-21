import 'package:equatable/equatable.dart';

import '../../../../core/constants/supported_symbols.dart';

/// Events for the Encoding BLoC.
abstract class EncodingEvent extends Equatable {
  const EncodingEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers fetching candle data for [symbol] and encoding it.
class FetchAndEncodeRequested extends EncodingEvent {
  final String symbol;

  const FetchAndEncodeRequested({
    this.symbol = SupportedSymbols.defaultSymbol,
  });

  @override
  List<Object?> get props => [symbol];
}
