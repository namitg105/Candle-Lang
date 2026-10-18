import 'package:equatable/equatable.dart';

/// A half-open span [start, end) in the encoded candle string
/// where a pattern was matched.
class MatchSpan extends Equatable {
  /// Inclusive start index.
  final int start;

  /// Exclusive end index.
  final int end;

  const MatchSpan({required this.start, required this.end});

  /// Number of characters in the match.
  int get length => end - start;

  /// Extract the matched substring from [text].
  String substring(String text) => text.substring(start, end);

  @override
  List<Object?> get props => [start, end];

  @override
  String toString() => 'MatchSpan($start, $end)';
}
