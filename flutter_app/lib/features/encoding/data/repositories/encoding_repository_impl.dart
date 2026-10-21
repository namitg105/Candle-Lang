import 'package:dartz/dartz.dart';

import '../../../../core/constants/alphabet.dart';
import '../../../../core/constants/supported_symbols.dart';
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
  Future<Either<Failure, List<Candle>>> fetchCandles({
    required String symbol,
  }) async {
    try {
      final candles = await remoteDataSource.fetchCandles(symbol: symbol);
      return Right(candles);
    } on ServerException catch (e) {
      // The bundled offline asset only ever holds AAPL data, so it can only
      // stand in for a live failure when AAPL itself was requested --
      // otherwise we'd silently show AAPL candles mislabeled as whatever
      // symbol the user actually picked.
      if (symbol != SupportedSymbols.defaultSymbol) {
        return Left(ServerFailure(e.message));
      }
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

      // Pass 1: compute every candle's raw body% (and, from candle 2
      // onward, gap%) with no classification decisions yet. We need the
      // whole set first so we can calibrate the U/D/F/G cutoffs to how
      // much THIS stock actually moves at THIS timeframe -- see
      // Alphabet's doc comment for why a fixed percentage can't work for
      // both 1-minute and daily candles.
      final bodyPercents = List<double>.filled(candles.length, 0.0);
      final gapPercents = List<double>.filled(candles.length, 0.0);

      for (var i = 0; i < candles.length; i++) {
        final candle = candles[i];
        bodyPercents[i] = candle.open == 0
            ? 0.0
            : (candle.close - candle.open).abs() / candle.open;

        if (i > 0) {
          final prevClose = candles[i - 1].close;
          gapPercents[i] = prevClose == 0
              ? 0.0
              : (candle.open - prevClose).abs() / prevClose;
        }
      }

      // gapPercents[0] is always 0 (no previous candle to gap from) and
      // would just water down the average, so it's excluded here.
      final bodyThreshold =
          _average(bodyPercents) * Alphabet.bodyThresholdFactor;
      final gapThreshold =
          _average(gapPercents.skip(1).toList()) * Alphabet.gapThresholdFactor;

      // Pass 2: classify every candle using those calibrated cutoffs.
      final buffer = StringBuffer();
      final traces = <EncodingTrace>[];

      for (var i = 0; i < candles.length; i++) {
        final candle = candles[i];
        final bodyPercent = bodyPercents[i];
        final gapPercent = gapPercents[i];
        final String symbol;

        if (i == 0) {
          // First candle: no previous close → classify by body only.
          symbol = _classifyBody(candle, bodyPercent, bodyThreshold);
        } else if (gapPercent > gapThreshold) {
          // Subsequent candles: gap takes priority over body.
          symbol = Alphabet.gap;
        } else {
          symbol = _classifyBody(candle, bodyPercent, bodyThreshold);
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

  /// Classifies a candle as U, D, or F based on body size relative to
  /// [bodyThreshold] (calibrated from the whole candle set -- see
  /// [encodeCandles]).
  String _classifyBody(Candle candle, double bodyPercent, double bodyThreshold) {
    if (bodyPercent <= bodyThreshold) {
      return Alphabet.flat;
    }
    return candle.isBullish ? Alphabet.up : Alphabet.down;
  }

  /// Mean of a list of percentages; 0 for an empty list (e.g. a single
  /// candle has no gaps to average) rather than dividing by zero.
  double _average(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
