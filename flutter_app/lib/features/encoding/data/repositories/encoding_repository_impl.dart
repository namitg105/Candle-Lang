import 'package:dartz/dartz.dart';

import '../../../../core/constants/alphabet.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/candle.dart';
import '../../domain/entities/encoded_result.dart';
import '../../domain/repositories/encoding_repository.dart';
import '../datasources/candle_local_data_source.dart';
import '../datasources/candle_remote_data_source.dart';

/// Concrete implementation of [EncodingRepository].
///
/// Fetching strategy: network-first with bundled-asset fallback.
/// Encoding is a pure, synchronous computation.
class EncodingRepositoryImpl implements EncodingRepository {
  final CandleRemoteDataSource remoteDataSource;
  final CandleLocalDataSource localDataSource;

  EncodingRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  // ---------------------------------------------------------------------------
  // Fetch candles — remote first, local fallback
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, List<Candle>>> fetchCandles() async {
    try {
      final candles = await remoteDataSource.fetchCandles();
      return Right(candles);
    } on ServerException {
      // Remote failed — try the bundled asset.
      try {
        final candles = await localDataSource.fetchCandles();
        return Right(candles);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Encode candles → {U, D, F, G}*
  // ---------------------------------------------------------------------------

  @override
  Either<Failure, EncodedResult> encodeCandles(List<Candle> candles) {
    try {
      if (candles.isEmpty) {
        return const Right(
          EncodedResult(encoded: '', trace: [], candles: []),
        );
      }

      final buffer = StringBuffer();
      final traces = <EncodingTrace>[];

      for (var i = 0; i < candles.length; i++) {
        final candle = candles[i];
        final double bodyPercent;
        final double gapPercent;
        final String symbol;

        // Body percent = |close - open| / open
        bodyPercent = candle.open == 0
            ? 0.0
            : (candle.close - candle.open).abs() / candle.open;

        if (i == 0) {
          // First candle: no previous close → classify by body only.
          gapPercent = 0.0;
          symbol = _classifyBody(candle, bodyPercent);
        } else {
          // Subsequent candles: gap takes priority.
          final prevClose = candles[i - 1].close;
          gapPercent =
              prevClose == 0 ? 0.0 : (candle.open - prevClose).abs() / prevClose;

          if (gapPercent > Alphabet.gapThreshold) {
            symbol = Alphabet.gap;
          } else {
            symbol = _classifyBody(candle, bodyPercent);
          }
        }

        buffer.write(symbol);
        traces.add(EncodingTrace(
          date: candle.date,
          symbol: symbol,
          gapPercent: gapPercent,
          bodyPercent: bodyPercent,
        ));
      }

      return Right(EncodedResult(
        encoded: buffer.toString(),
        trace: traces,
        candles: candles,
      ));
    } catch (e) {
      return Left(ComputationFailure('Encoding failed: $e'));
    }
  }

  /// Classifies a candle as U, D, or F based on body size.
  String _classifyBody(Candle candle, double bodyPercent) {
    if (bodyPercent <= Alphabet.bodyThreshold) {
      return Alphabet.flat;
    }
    return candle.isBullish ? Alphabet.up : Alphabet.down;
  }
}
