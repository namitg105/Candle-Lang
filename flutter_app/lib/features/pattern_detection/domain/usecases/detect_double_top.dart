import '../../../automaton/domain/entities/match_span.dart';
import '../repositories/pattern_repository.dart';

/// Detects the Double Top hybrid pattern:
/// regex pre-filter (U+DU+D shape) + numeric peak-height post-check.
///
/// This is a synchronous operation — no Either wrapping needed since
/// the hybrid detection itself doesn't do I/O.
class DetectDoubleTop {
  final PatternRepository repository;

  DetectDoubleTop(this.repository);

  List<MatchSpan> call(DetectDoubleTopParams params) {
    return repository.detectDoubleTop(
      encodedString: params.encodedString,
      highs: params.highs,
      tolerance: params.tolerance,
    );
  }
}

class DetectDoubleTopParams {
  final String encodedString;
  final List<double> highs;
  final double tolerance;

  const DetectDoubleTopParams({
    required this.encodedString,
    required this.highs,
    this.tolerance = 0.015,
  });
}
