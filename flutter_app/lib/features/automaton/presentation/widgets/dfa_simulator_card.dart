import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/automaton_inspection.dart';
import '../../domain/entities/match_span.dart';

/// Interactive simulator: type any string over Σ = {U, D, F, G} and see
/// every place this pattern occurs inside it -- a substring search over
/// the NFA, same as what the Market Chart screen runs on real candle
/// data. A string can contain the pattern without being made of nothing
/// else BUT the pattern, so this only ever answers "where does it show
/// up", not "is the whole string just this pattern".
class DfaSimulatorCard extends StatefulWidget {
  final AutomatonInspection inspection;
  final ValueChanged<String> onSimulate;
  final DfaTraceResult? traceResult;
  final List<MatchSpan>? substringMatches;

  const DfaSimulatorCard({
    super.key,
    required this.inspection,
    required this.onSimulate,
    this.traceResult,
    this.substringMatches,
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
    final matches = widget.substringMatches;

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
                  const Icon(Icons.search, size: 18, color: AppTheme.bullishColor),
                  const SizedBox(width: 8),
                  Text(
                    'Pattern Matches',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (matches == null)
                const SizedBox.shrink()
              else if (matches.isEmpty)
                Row(
                  children: [
                    const Icon(Icons.search_off, color: AppTheme.bearishColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'NOT FOUND anywhere in "${trace.input}"',
                      style: const TextStyle(
                        color: AppTheme.bearishColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FOUND ${matches.length} match${matches.length == 1 ? '' : 'es'}',
                      style: const TextStyle(
                        color: AppTheme.bullishColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: matches.map((m) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.bullishColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.bullishColor),
                          ),
                          child: Text(
                            '[${m.start}–${m.end}) = "${m.substring(trace.input)}"',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
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
}
