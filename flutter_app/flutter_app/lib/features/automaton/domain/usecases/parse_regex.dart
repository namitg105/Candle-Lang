import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/regex_node.dart';
import '../repositories/automaton_repository.dart';

class ParseRegex extends UseCase<RegexNode, ParseRegexParams> {
  final AutomatonRepository repository;

  ParseRegex(this.repository);

  @override
  Future<Either<Failure, RegexNode>> call(ParseRegexParams params) async {
    return repository.parseRegex(params.pattern);
  }
}

class ParseRegexParams {
  final String pattern;
  const ParseRegexParams(this.pattern);
}
