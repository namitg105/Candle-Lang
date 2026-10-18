import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/candle.dart';
import '../entities/encoded_result.dart';
import '../repositories/encoding_repository.dart';

/// Encodes a list of OHLC candles into a {U,D,F,G} string.
class EncodeCandles implements UseCase<EncodedResult, List<Candle>> {
  final EncodingRepository repository;

  EncodeCandles(this.repository);

  @override
  Future<Either<Failure, EncodedResult>> call(List<Candle> params) async {
    // Synchronous computation, wrapped in Future for UseCase interface.
    return repository.encodeCandles(params);
  }
}
