import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/automaton_inspection.dart';

/// Shows state count reduction from NFA -> DFA -> Minimized DFA.
class StateReductionCard extends StatelessWidget {
  final AutomatonInspection inspection;

  const StateReductionCard({super.key, required this.inspection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduction = inspection.reductionPercentage.toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Automata Optimization',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.bullishColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.bullishColor),
                  ),
                  child: Text(
                    '-$reduction% States',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.bullishColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStage(
                    context,
                    title: "Thompson's NFA",
                    count: inspection.nfaStates,
                    subtitle: 'ε-transitions included',
                    color: Colors.blueAccent,
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 18, color: AppTheme.textMuted),
                Expanded(
                  child: _buildStage(
                    context,
                    title: 'Subset DFA',
                    count: inspection.dfaStates,
                    subtitle: 'Deterministic states',
                    color: Colors.amberAccent,
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 18, color: AppTheme.textMuted),
                Expanded(
                  child: _buildStage(
                    context,
                    title: 'Minimized DFA',
                    count: inspection.minDfaStates,
                    subtitle: 'Optimal equivalence',
                    color: AppTheme.bullishColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage(
    BuildContext context, {
    required String title,
    required int count,
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            '$count',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
