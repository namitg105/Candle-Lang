import 'package:flutter_test/flutter_test.dart';
import 'package:candlelang_app/features/automaton/data/repositories/automaton_repository_impl.dart';
import 'package:candlelang_app/features/automaton/domain/usecases/inspect_automaton.dart';

void main() {
  late AutomatonRepositoryImpl repository;
  late InspectAutomaton inspectAutomaton;

  setUp(() {
    repository = AutomatonRepositoryImpl();
    inspectAutomaton = InspectAutomaton(repository);
  });

  test('Three White Soldiers (U{3,}) pipeline succeeds', () async {
    final result = await inspectAutomaton(const InspectAutomatonParams('U{3,}'));
    expect(result.isRight(), isTrue);

    final inspection = result.getOrElse(() => throw StateError(''));
    expect(inspection.nfaStates, greaterThan(0));
    expect(inspection.dfaStates, greaterThan(0));
    expect(inspection.minDfaStates, greaterThan(0));
    expect(inspection.minDfaStates, lessThanOrEqualTo(inspection.dfaStates));

    // Simulation check
    expect(inspection.simulate('UUU').accepted, isTrue);
    expect(inspection.simulate('UUUU').accepted, isTrue);
    expect(inspection.simulate('UU').accepted, isFalse);
    expect(inspection.simulate('D').accepted, isFalse);
  });
}
