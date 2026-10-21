import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/encode_candles.dart';
import '../../domain/usecases/fetch_candle_data.dart';
import 'encoding_event.dart';
import 'encoding_state.dart';

/// BLoC that orchestrates fetching candle data and encoding it.
class EncodingBloc extends Bloc<EncodingEvent, EncodingState> {
  final FetchCandleData fetchCandleData;
  final EncodeCandles encodeCandles;

  EncodingBloc({
    required this.fetchCandleData,
    required this.encodeCandles,
  }) : super(const EncodingInitial()) {
    on<FetchAndEncodeRequested>(_onFetchAndEncode);
  }

  Future<void> _onFetchAndEncode(
    FetchAndEncodeRequested event,
    Emitter<EncodingState> emit,
  ) async {
    emit(const EncodingLoading());

    // Step 1: Fetch candle data for the requested symbol.
    final candlesResult = await fetchCandleData(event.symbol);

    await candlesResult.fold(
      (failure) async {
        emit(EncodingError(failure.message));
      },
      (candles) async {
        // Step 2: Encode the fetched candles via the use case.
        final encodeResult = await encodeCandles(candles);

        encodeResult.fold(
          (failure) => emit(EncodingError(failure.message)),
          (result) => emit(EncodingLoaded(candles: candles, result: result)),
        );
      },
    );
  }
}
