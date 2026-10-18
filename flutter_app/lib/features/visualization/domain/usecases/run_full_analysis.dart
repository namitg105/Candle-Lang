import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/analysis_result.dart';
import '../repositories/analysis_repository.dart';

/// Executes the full CandleLang analysis pipeline.
///
/// Single responsibility: just delegates to the repository.
/// Takes [NoParams] because the pipeline is self-contained
/// (data source is configured at the repository level).
class RunFullAnalysis extends UseCase<AnalysisResult, NoParams> {
  final AnalysisRepository repository;

  RunFullAnalysis(this.repository);

  @override
  Future<Either<Failure, AnalysisResult>> call(NoParams params) {
    return repository.runFullAnalysis();
  }
}
