import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/automaton_inspection.dart';

/// Interactive simulator allowing string evaluation on the constructed DFA.
class DfaSimulatorCard extends StatefulWidget {
  final AutomatonInspection inspection;
  final ValueChanged<String> onSimulate;
  final DfaTraceResult? traceResult;

  const DfaSimulatorCard({
    super.key,
    required this.inspection,
    required this.onSimulate,
    this.traceResult,
  });

  @override
  State<DfaSimulatorCard> createState() => _DfaSimulatorCardState();
}

class _DfaSimulatorCardState extends State<DfaSimulatorCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trace = widget.traceResult;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.play_circle_outline, size: 20, color: AppTheme.bullishColor),
                const SizedBox(width: 8),
                Text(
                  'Interactive String Simulator',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Test any string over Σ = {U, D, F, G} against the Minimized DFA.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Enter candidate string (e.g. UUU, DDFUU)',
                filled: true,
                fillColor: AppTheme.gridColor.withValues(alpha: 0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Simulate',
                  onPressed: () => widget.onSimulate(_controller.text),
                ),
              ),
              onSubmitted: widget.onSimulate,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                _chip('UUU'),
                _chip('UUUGDF'),
                _chip('DDFUU'),
                _chip('GU'),
                _chip('FF'),
              ],
            ),
            if (trace != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    trace.accepted ? Icons.check_circle : Icons.cancel,
                    color: trace.accepted ? AppTheme.bullishColor : AppTheme.bearishColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    trace.accepted ? 'STRING ACCEPTED' : 'STRING REJECTED',
                    style: TextStyle(
                      color: trace.accepted ? AppTheme.bullishColor : AppTheme.bearishColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Final state: q${trace.path.last}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'State Transition Path:',
                style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < trace.steps.length; i++) ...[
                      _stateBadge(trace.steps[i].fromState),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '──(${trace.steps[i].symbol})──►',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ),
                    ],
                    _stateBadge(trace.path.last, isFinal: true),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
      onPressed: () {
        _controller.text = text;
        widget.onSimulate(text);
      },
    );
  }

  Widget _stateBadge(int s, {bool isFinal = false}) {
    final isAccept = widget.inspection.minDfa.accepts.contains(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAccept
            ? AppTheme.bullishColor.withValues(alpha: 0.2)
            : AppTheme.gridColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAccept ? AppTheme.bullishColor : Colors.transparent,
          width: isFinal ? 2 : 1,
        ),
      ),
      child: Text(
        'q$s${isAccept ? ' ◎' : ''}',
        style: TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          color: isAccept ? AppTheme.bullishColor : null,
          fontSize: 12,
        ),
      ),
    );
  }
}
