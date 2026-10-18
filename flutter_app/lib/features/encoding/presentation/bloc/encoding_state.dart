import 'package:equatable/equatable.dart';

import '../../domain/entities/candle.dart';
import '../../domain/entities/encoded_result.dart';

/// States for the Encoding BLoC.
abstract class EncodingState extends Equatable {
  const EncodingState();

  @override
  List<Object?> get props => [];
}

class EncodingInitial extends EncodingState {
  const EncodingInitial();
}

class EncodingLoading extends EncodingState {
  const EncodingLoading();
}

class EncodingLoaded extends EncodingState {
  final List<Candle> candles;
  final EncodedResult result;

  const EncodingLoaded({required this.candles, required this.result});

  @override
  List<Object?> get props => [candles, result];
}

class EncodingError extends EncodingState {
  final String message;

  const EncodingError(this.message);

  @override
  List<Object?> get props => [message];
}
