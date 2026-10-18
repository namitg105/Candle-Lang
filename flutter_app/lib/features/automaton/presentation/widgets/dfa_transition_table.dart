import 'package:flutter/material.dart';

import '../../../../core/constants/alphabet.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dfa.dart';

/// Renders the complete DFA State Transition Table.
class DfaTransitionTable extends StatelessWidget {
  final Dfa dfa;
  final int? activeState;

  const DfaTransitionTable({
    super.key,
    required this.dfa,
    this.activeState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_chart, size: 20, color: AppTheme.bullishColor),
                const SizedBox(width: 8),
                Text(
                  'DFA Transition Matrix (δ: Q × Σ → Q)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Rows represent internal states; columns represent input candle symbols.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppTheme.gridColor),
                columns: const [
                  DataColumn(label: Text('State', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('U (Up)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('D (Down)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('F (Flat)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('G (Gap)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('NFA State Set (Label)', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: List.generate(dfa.numStates, (s) {
                  final isStart = s == dfa.start;
                  final isAccept = dfa.accepts.contains(s);
                  final isActive = s == activeState;
                  final trans = dfa.transitions[s] ?? {};
                  final label = dfa.stateLabels?[s] ?? 'q$s';

                  return DataRow(
                    color: WidgetStateProperty.resolveWith((states) {
                      if (isActive) return AppTheme.bullishColor.withValues(alpha: 0.2);
                      if (isAccept) return AppTheme.bullishColor.withValues(alpha: 0.08);
                      return null;
                    }),
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isStart)
                              const Icon(Icons.arrow_right_alt, color: Colors.blueAccent, size: 16),
                            Text(
                              'q$s',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                color: isAccept ? AppTheme.bullishColor : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        _buildStatusBadge(isStart: isStart, isAccept: isAccept),
                      ),
                      DataCell(_buildTargetCell(trans[Alphabet.up])),
                      DataCell(_buildTargetCell(trans[Alphabet.down])),
                      DataCell(_buildTargetCell(trans[Alphabet.flat])),
                      DataCell(_buildTargetCell(trans[Alphabet.gap])),
                      DataCell(
                        Text(
                          label,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge({required bool isStart, required bool isAccept}) {
    if (isStart && isAccept) {
      return const Text('Start / Accept ◎', style: TextStyle(color: AppTheme.bullishColor, fontSize: 11));
    }
    if (isStart) {
      return const Text('Start →', style: TextStyle(color: Colors.blueAccent, fontSize: 11));
    }
    if (isAccept) {
      return const Text('Accept ◎', style: TextStyle(color: AppTheme.bullishColor, fontWeight: FontWeight.bold, fontSize: 11));
    }
    return const Text('Normal', style: TextStyle(color: AppTheme.textMuted, fontSize: 11));
  }

  Widget _buildTargetCell(int? target) {
    if (target == null) {
      return const Text('—', style: TextStyle(color: AppTheme.textMuted));
    }
    final isAccept = dfa.accepts.contains(target);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAccept
            ? AppTheme.bullishColor.withValues(alpha: 0.15)
            : AppTheme.gridColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'q$target',
        style: TextStyle(
          fontFamily: 'monospace',
          fontWeight: isAccept ? FontWeight.bold : FontWeight.normal,
          color: isAccept ? AppTheme.bullishColor : null,
        ),
      ),
    );
  }
}
