import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dfa.dart';
import '../repositories/automaton_repository.dart';

class MinimizeDfa extends UseCase<Dfa, MinimizeDfaParams> {
  final AutomatonRepository repository;

  MinimizeDfa(this.repository);

  @override
  Future<Either<Failure, Dfa>> call(MinimizeDfaParams params) async {
    return repository.minimizeDfa(params.dfa);
  }
}

class MinimizeDfaParams {
  final Dfa dfa;
  const MinimizeDfaParams(this.dfa);
}
