import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/match_span.dart';
import '../entities/nfa.dart';
import '../repositories/automaton_repository.dart';

class SearchNfa extends UseCase<List<MatchSpan>, SearchNfaParams> {
  final AutomatonRepository repository;

  SearchNfa(this.repository);

  @override
  Future<Either<Failure, List<MatchSpan>>> call(SearchNfaParams params) async {
    return repository.searchNfa(params.nfa, params.text);
  }
}

class SearchNfaParams {
  final Nfa nfa;
  final String text;
  const SearchNfaParams({required this.nfa, required this.text});
}
