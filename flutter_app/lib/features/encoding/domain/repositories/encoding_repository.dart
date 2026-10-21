import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/candle.dart';
import '../entities/encoded_result.dart';

/// Contract for fetching OHLC data and encoding it into {U,D,F,G}*.
abstract class EncodingRepository {
  /// Fetch historical OHLC candle data for [symbol] (network-first, asset
  /// fallback -- the fallback only ever covers [SupportedSymbols.defaultSymbol],
  /// see [EncodingRepositoryImpl] for why).
  Future<Either<Failure, List<Candle>>> fetchCandles({required String symbol});

  /// Encode a list of candles into a formal-language string.
  ///
  /// This is a pure computation — synchronous under the hood —
  /// but wrapped in [Either] for uniform error handling.
  Either<Failure, EncodedResult> encodeCandles(List<Candle> candles);
}
