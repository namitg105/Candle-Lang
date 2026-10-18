import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/candle.dart';
import '../entities/encoded_result.dart';

/// Contract for fetching OHLC data and encoding it into {U,D,F,G}*.
abstract class EncodingRepository {
  /// Fetch historical OHLC candle data (network-first, asset fallback).
  Future<Either<Failure, List<Candle>>> fetchCandles();

  /// Encode a list of candles into a formal-language string.
  ///
  /// This is a pure computation — synchronous under the hood —
  /// but wrapped in [Either] for uniform error handling.
  Either<Failure, EncodedResult> encodeCandles(List<Candle> candles);
}
