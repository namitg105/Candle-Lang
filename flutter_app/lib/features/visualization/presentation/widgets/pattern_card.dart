import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/analysis_result.dart';
import 'confidence_badge.dart';

/// Card showing one pattern's detection results and ML scores.
class PatternCard extends StatelessWidget {
  final PatternResultWithScores pattern;
  final void Function(int start, int end, bool isBullish)? onSelectMatch;
  final int? selectedStart;
  final int? selectedEnd;

  const PatternCard({
    super.key,
    required this.pattern,
    this.onSelectMatch,
    this.selectedStart,
    this.selectedEnd,
  });

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
        final isSelected = selectedStart == m.start && selectedEnd == m.end;
        return ListTile(
          dense: true,
          selected: isSelected,
          selectedTileColor: AppTheme.bullishColor.withValues(alpha: 0.1),
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConfidenceBadge(confidence: m.confidence),
              const SizedBox(width: 8),
              const Icon(Icons.visibility, size: 16, color: AppTheme.textMuted),
            ],
          ),
          onTap: () {
            onSelectMatch?.call(m.start, m.end, pattern.isBullish);
          },
        );
      }).toList(),
    );
  }
}
