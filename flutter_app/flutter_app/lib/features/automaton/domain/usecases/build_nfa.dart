import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/nfa.dart';
import '../entities/regex_node.dart';
import '../repositories/automaton_repository.dart';

class BuildNfa extends UseCase<Nfa, BuildNfaParams> {
  final AutomatonRepository repository;

  BuildNfa(this.repository);

  @override
  Future<Either<Failure, Nfa>> call(BuildNfaParams params) async {
    return repository.buildNfa(params.ast);
  }
}

class BuildNfaParams {
  final RegexNode ast;
  const BuildNfaParams(this.ast);
}
