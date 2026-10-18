import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/analysis_result.dart';
import 'confidence_badge.dart';

/// Card showing one pattern's detection results and ML scores.
///
/// Displays: pattern name, direction icon, match count,
/// automaton stats (NFA/DFA/minDFA states), cross-check status,
/// and a list of individual matches with confidence badges.
class PatternCard extends StatelessWidget {
  final PatternResultWithScores pattern;

  const PatternCard({super.key, required this.pattern});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        leading: Icon(
          pattern.isBullish ? Icons.trending_up : Icons.trending_down,
          color: pattern.isBullish
              ? AppTheme.bullishColor
              : AppTheme.bearishColor,
        ),
        title: Text(
          pattern.displayName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: _buildSubtitle(theme),
        children: [
          _buildAutomatonStats(theme),
          if (pattern.matches.isNotEmpty) _buildMatchList(theme),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    final matchCount = pattern.matches.length;
    final avg = pattern.averageConfidence;
    return Row(
      children: [
        Text(
          '$matchCount match${matchCount == 1 ? '' : 'es'}',
          style: theme.textTheme.bodySmall,
        ),
        if (matchCount > 0) ...[
          const SizedBox(width: 8),
          ConfidenceBadge(confidence: avg),
        ],
        const Spacer(),
        Icon(
          pattern.crossCheckPassed ? Icons.check_circle : Icons.warning,
          size: 16,
          color: pattern.crossCheckPassed
              ? AppTheme.bullishColor
              : AppTheme.bearishColor,
        ),
      ],
    );
  }

  /// Shows NFA states → DFA states → minimized DFA states.
  Widget _buildAutomatonStats(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _statChip('NFA', '${pattern.nfaStates}', theme),
          const Icon(Icons.arrow_right_alt, size: 16, color: AppTheme.textMuted),
          _statChip('DFA', '${pattern.dfaStates}', theme),
          const Icon(Icons.arrow_right_alt, size: 16, color: AppTheme.textMuted),
          _statChip('Min', '${pattern.minDfaStates}', theme),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppTheme.gridColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMatchList(ThemeData theme) {
    return Column(
      children: pattern.matches.map((m) {
        return ListTile(
          dense: true,
          leading: Text(
            '[${m.start}–${m.end})',
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
          title: Text(
            m.substring,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: ConfidenceBadge(confidence: m.confidence),
        );
      }).toList(),
    );
  }
}
