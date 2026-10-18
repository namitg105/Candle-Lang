import 'package:equatable/equatable.dart';

/// Events for the Encoding BLoC.
abstract class EncodingEvent extends Equatable {
  const EncodingEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers fetching candle data and encoding it.
class FetchAndEncodeRequested extends EncodingEvent {
  const FetchAndEncodeRequested();
}
