import 'package:equatable/equatable.dart';

enum PatternType { regular, hybrid }

enum PatternDirection { bullish, bearish, neutral }

/// Defines a candlestick pattern to search for.
class PatternDefinition extends Equatable {
  final String name;
  final String? regex;
  final String displayName;
  final PatternType type;
  final PatternDirection direction;
  final String meaning;

  const PatternDefinition({
    required this.name,
    this.regex,
    required this.displayName,
    required this.type,
    required this.direction,
    required this.meaning,
  });

  bool get isRegular => type == PatternType.regular;
  bool get isHybrid => type == PatternType.hybrid;
  bool get isBullish => direction == PatternDirection.bullish;
  bool get isBearish => direction == PatternDirection.bearish;

  @override
  List<Object?> get props =>
      [name, regex, displayName, type, direction, meaning];
}
