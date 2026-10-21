import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/analysis_result.dart';
import '../repositories/analysis_repository.dart';

/// Executes the full CandleLang analysis pipeline for a given stock
/// [symbol] (e.g. 'AAPL', 'MSFT').
///
/// Single responsibility: just delegates to the repository.
class RunFullAnalysis extends UseCase<AnalysisResult, String> {
  final AnalysisRepository repository;

  RunFullAnalysis(this.repository);

  @override
  Future<Either<Failure, AnalysisResult>> call(String symbol) {
    return repository.runFullAnalysis(symbol: symbol);
  }
}
