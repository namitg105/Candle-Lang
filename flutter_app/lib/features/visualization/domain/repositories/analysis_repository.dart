import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/analysis_result.dart';

/// Contract for orchestrating the full analysis pipeline:
/// fetch → encode → detect patterns → ML score → aggregate.
abstract class AnalysisRepository {
  /// Runs the entire CandleLang pipeline end-to-end for [symbol].
  ///
  /// 1. Fetches OHLC data for [symbol] (network-first, asset fallback).
  /// 2. Encodes candles into {U,D,F,G}* string.
  /// 3. Detects all 8 patterns via NFA/DFA pipeline.
  /// 4. Scores each match with logistic regression ML model.
  /// 5. Packages everything into an [AnalysisResult].
  Future<Either<Failure, AnalysisResult>> runFullAnalysis({
    required String symbol,
  });
}
