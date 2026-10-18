import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/automaton_inspection.dart';
import '../repositories/automaton_repository.dart';

/// Runs regex -> NFA -> DFA -> Minimized DFA pipeline.
class InspectAutomaton extends UseCase<AutomatonInspection, InspectAutomatonParams> {
  final AutomatonRepository repository;

  InspectAutomaton(this.repository);

  @override
  Future<Either<Failure, AutomatonInspection>> call(InspectAutomatonParams params) async {
    final astResult = repository.parseRegex(params.regex);
    if (astResult.isLeft()) {
      return Left(astResult.fold((f) => f, (_) => throw StateError('')));
    }
    final ast = astResult.getOrElse(() => throw StateError(''));

    final nfaResult = repository.buildNfa(ast);
    if (nfaResult.isLeft()) {
      return Left(nfaResult.fold((f) => f, (_) => throw StateError('')));
    }
    final nfa = nfaResult.getOrElse(() => throw StateError(''));

    final dfaResult = repository.buildDfa(nfa);
    if (dfaResult.isLeft()) {
      return Left(dfaResult.fold((f) => f, (_) => throw StateError('')));
    }
    final dfa = dfaResult.getOrElse(() => throw StateError(''));

    final minDfaResult = repository.minimizeDfa(dfa);
    if (minDfaResult.isLeft()) {
      return Left(minDfaResult.fold((f) => f, (_) => throw StateError('')));
    }
    final minDfa = minDfaResult.getOrElse(() => throw StateError(''));

    return Right(AutomatonInspection(
      regex: params.regex,
      ast: ast,
      nfa: nfa,
      dfa: dfa,
      minDfa: minDfa,
    ));
  }
}

class InspectAutomatonParams {
  final String regex;
  const InspectAutomatonParams(this.regex);
}
