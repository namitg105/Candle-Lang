import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/pattern_result.dart';
import '../repositories/pattern_repository.dart';

/// Runs every pattern definition through the NFA/DFA pipeline.
class DetectAllPatterns
    extends UseCase<List<PatternResult>, DetectAllPatternsParams> {
  final PatternRepository repository;

  DetectAllPatterns(this.repository);

  @override
  Future<Either<Failure, List<PatternResult>>> call(
    DetectAllPatternsParams params,
  ) async {
    try {
      final results = await repository.detectAllPatterns(
        encodedString: params.encodedString,
        highs: params.highs,
      );
      return Right(results);
    } catch (e) {
      return Left(ComputationFailure('Pattern detection failed: $e'));
    }
  }
}

class DetectAllPatternsParams {
  final String encodedString;
  final List<double> highs;

  const DetectAllPatternsParams({
    required this.encodedString,
    required this.highs,
  });
}
