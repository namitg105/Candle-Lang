import '../../domain/entities/pattern_definition.dart';

/// Hardcoded list of the 8 candlestick patterns CandleLang recognises.
///
/// Seven are pure regular patterns (matched entirely by the NFA/DFA pipeline).
/// One — double_top — is a hybrid pattern that uses a regex pre-filter
/// followed by a numeric peak-height post-check, demonstrating the limits
/// of regular languages.
class PatternDefinitionsSource {
  PatternDefinitionsSource._();

  static const List<PatternDefinition> definitions = [
    // ── Bullish regular patterns ──────────────────────────────────────
    PatternDefinition(
      name: 'three_white_soldiers',
      regex: 'U{3,}',
      displayName: 'Three White Soldiers',
      type: PatternType.regular,
      direction: PatternDirection.bullish,
      meaning: 'Three or more consecutive bullish candles — '
          'strong buying momentum.',
    ),
    PatternDefinition(
      name: 'bullish_reversal',
      regex: 'D+FU+',
      displayName: 'Bullish Reversal',
      type: PatternType.regular,
      direction: PatternDirection.bullish,
      meaning: 'Down run followed by a doji then up run — '
          'potential trend reversal.',
    ),
    PatternDefinition(
      name: 'gap_and_go',
      regex: 'GU+',
      displayName: 'Gap & Go',
      type: PatternType.regular,
      direction: PatternDirection.bullish,
      meaning: 'Gap up followed by bullish continuation — '
          'breakout momentum.',
    ),

    // ── Bearish regular patterns ──────────────────────────────────────
    PatternDefinition(
      name: 'three_black_crows',
      regex: 'D{3,}',
      displayName: 'Three Black Crows',
      type: PatternType.regular,
      direction: PatternDirection.bearish,
      meaning: 'Three or more consecutive bearish candles — '
          'strong selling pressure.',
    ),
    PatternDefinition(
      name: 'bearish_reversal',
      regex: 'U+FD+',
      displayName: 'Bearish Reversal',
      type: PatternType.regular,
      direction: PatternDirection.bearish,
      meaning: 'Up run followed by a doji then down run — '
          'potential top reversal.',
    ),
    PatternDefinition(
      name: 'exhaustion_gap',
      regex: 'U{2,}GD',
      displayName: 'Exhaustion Gap',
      type: PatternType.regular,
      direction: PatternDirection.bearish,
      meaning: 'Bullish run, gap up, then bearish candle — '
          'potential exhaustion of buying.',
    ),

    // ── Neutral regular pattern ───────────────────────────────────────
    PatternDefinition(
      name: 'indecision_cluster',
      regex: 'F{2,}',
      displayName: 'Indecision Cluster',
      type: PatternType.regular,
      direction: PatternDirection.neutral,
      meaning: 'Two or more doji candles — '
          'market indecision, breakout imminent.',
    ),

    // ── Hybrid pattern (regex + numeric post-check) ───────────────────
    PatternDefinition(
      name: 'double_top',
      regex: 'U+DU+D',
      displayName: 'Double Top',
      type: PatternType.hybrid,
      direction: PatternDirection.bearish,
      meaning: 'Two peaks at roughly equal height — '
          'bearish reversal signal (requires numeric verification).',
    ),
  ];
}
