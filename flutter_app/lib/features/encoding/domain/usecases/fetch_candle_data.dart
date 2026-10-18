import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/candle.dart';
import '../repositories/encoding_repository.dart';

/// Fetches historical OHLC candle data.
class FetchCandleData implements UseCase<List<Candle>, NoParams> {
  final EncodingRepository repository;

  FetchCandleData(this.repository);

  @override
  Future<Either<Failure, List<Candle>>> call(NoParams params) async {
    return await repository.fetchCandles();
  }
}
