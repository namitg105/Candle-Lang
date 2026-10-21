import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/candle.dart';
import '../repositories/encoding_repository.dart';

/// Fetches historical OHLC candle data for a given stock [symbol].
class FetchCandleData implements UseCase<List<Candle>, String> {
  final EncodingRepository repository;

  FetchCandleData(this.repository);

  @override
  Future<Either<Failure, List<Candle>>> call(String symbol) async {
    return await repository.fetchCandles(symbol: symbol);
  }
}
