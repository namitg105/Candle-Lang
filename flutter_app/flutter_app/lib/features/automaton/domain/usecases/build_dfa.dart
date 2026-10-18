import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dfa.dart';
import '../entities/nfa.dart';
import '../repositories/automaton_repository.dart';

class BuildDfa extends UseCase<Dfa, BuildDfaParams> {
  final AutomatonRepository repository;

  BuildDfa(this.repository);

  @override
  Future<Either<Failure, Dfa>> call(BuildDfaParams params) async {
    return repository.buildDfa(params.nfa);
  }
}

class BuildDfaParams {
  final Nfa nfa;
  const BuildDfaParams(this.nfa);
}
