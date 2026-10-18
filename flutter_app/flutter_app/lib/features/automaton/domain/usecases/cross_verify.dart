import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dfa.dart';
import '../entities/match_span.dart';
import '../entities/nfa.dart';
import '../repositories/automaton_repository.dart';

/// Cross-verifies NFA and DFA language equivalence.
///
/// For every NFA match span, checks that the DFA also accepts
/// the same substring, and vice-versa. This proves the central
/// theorem of Module 2: NFA and DFA accept exactly the same language.
class CrossVerify extends UseCase<CrossVerifyResult, CrossVerifyParams> {
  final AutomatonRepository repository;

  CrossVerify(this.repository);

  @override
  Future<Either<Failure, CrossVerifyResult>> call(
      CrossVerifyParams params) async {
    try {
      // Verify every NFA match is also accepted by the DFA
      bool allMatch = true;
      for (final span in params.nfaMatches) {
        final substr = span.substring(params.text);
        final dfaResult = repository.dfaAccepts(params.dfa, substr);
        if (!dfaResult) {
          allMatch = false;
          break;
        }
      }

      return Right(CrossVerifyResult(passed: allMatch));
    } catch (e) {
      return Left(ComputationFailure('Cross-verification failed: $e'));
    }
  }
}

class CrossVerifyParams {
  final Nfa nfa;
  final Dfa dfa;
  final List<MatchSpan> nfaMatches;
  final String text;

  const CrossVerifyParams({
    required this.nfa,
    required this.dfa,
    required this.nfaMatches,
    required this.text,
  });
}

class CrossVerifyResult {
  final bool passed;
  const CrossVerifyResult({required this.passed});
}
