import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../encoding/domain/repositories/encoding_repository.dart';
import '../../../ml_scoring/domain/repositories/ml_repository.dart';
import '../../../pattern_detection/domain/entities/pattern_result.dart';
import '../../../pattern_detection/domain/repositories/pattern_repository.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/repositories/analysis_repository.dart';

/// Orchestrates the full pipeline by delegating to each feature's repository.
///
/// Dependency flow (Clean Architecture — all inward):
///   AnalysisRepositoryImpl → EncodingRepository (interface)
///                          → PatternRepository  (interface)
///                          → MlRepository        (interface)
class AnalysisRepositoryImpl implements AnalysisRepository {
  final EncodingRepository encodingRepository;
  final PatternRepository patternRepository;
  final MlRepository mlRepository;

  AnalysisRepositoryImpl({
    required this.encodingRepository,
    required this.patternRepository,
    required this.mlRepository,
  });

  @override
  Future<Either<Failure, AnalysisResult>> runFullAnalysis() async {
    // Step 1: Fetch OHLC data.
    final candlesResult = await encodingRepository.fetchCandles();
    if (candlesResult.isLeft()) {
      return Left(candlesResult.fold((f) => f, (_) => throw StateError('')));
    }
    final candles = candlesResult.getOrElse(() => []);

    // Step 2: Encode candles into {U,D,F,G}* string.
    final encodeResult = encodingRepository.encodeCandles(candles);
    if (encodeResult.isLeft()) {
      return Left(encodeResult.fold((f) => f, (_) => throw StateError('')));
    }
    final encodedResult = encodeResult.getOrElse(() => throw StateError(''));

    // Step 3: Detect all patterns via NFA/DFA pipeline.
    final highs = candles.map((c) => c.high).toList();
    final List<PatternResult> patternResults;
    try {
      patternResults = await patternRepository.detectAllPatterns(
        encodedString: encodedResult.encoded,
        highs: highs,
      );
    } catch (e) {
      return Left(ComputationFailure('Pattern detection failed: $e'));
    }

    // Step 4: Train the confidence model once on every match found across
    // every pattern, then score each match with the fitted model.
    final scoredByPattern = mlRepository.trainAndScore(
      patternResults: patternResults,
      encodedString: encodedResult.encoded,
      candles: candles,
    );

    final scoredPatterns = patternResults.map((pr) {
      final scored = scoredByPattern[pr.definition.name] ?? const [];
      final scoredMatches = scored
          .map((sm) => ScoredMatchResult(
                start: sm.start,
                end: sm.end,
                substring: sm.substring,
                confidence: sm.confidence,
              ))
          .toList();

      return PatternResultWithScores(
        definition: pr.definition,
        matches: scoredMatches,
        nfaStates: pr.nfaStates,
        dfaStates: pr.dfaStates,
        minDfaStates: pr.minDfaStates,
        crossCheckPassed: pr.crossCheckPassed,
      );
    }).toList();

    // Step 5: Build the aggregated result.
    final firstDate = candles.first.date;
    final lastDate = candles.last.date;
    return Right(AnalysisResult(
      symbol: 'AAPL',
      dateRange: '$firstDate → $lastDate',
      numCandles: candles.length,
      encodedString: encodedResult.encoded,
      candles: candles,
      patterns: scoredPatterns,
    ));
  }
}
