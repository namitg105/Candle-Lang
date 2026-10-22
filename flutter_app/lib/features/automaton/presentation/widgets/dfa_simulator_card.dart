import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/automaton_inspection.dart';
import '../../domain/entities/match_span.dart';

/// Interactive simulator allowing string evaluation on the constructed DFA.
///
/// Answers TWO different questions about the same candidate string, and
/// shows both so they're never confused with each other:
///  1. Full-string match — does the ENTIRE string belong to the pattern,
///     start to finish? ([traceResult], standard DFA acceptance.)
///  2. Substring search — does the pattern occur ANYWHERE inside the
///     string? ([substringMatches] — the same check the Market Chart
///     screen runs when scanning 120 candles of real data.)
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

              // ── Question 1: full-string match ──────────────────────
              Text(
                '1. FULL-STRING MATCH',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Does the WHOLE string "${trace.input}" belong to this '
                'pattern, start to finish?',
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 6),
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

              // ── Question 2: substring search (what Market Chart does) ──
              const Divider(height: 24),
              Text(
                '2. PATTERN FOUND INSIDE THE STRING?',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Does this pattern occur ANYWHERE inside "${trace.input}", even '
                'as part of something longer? This is the check the Market '
                'Chart screen runs on real candle data — so it can disagree '
                'with Question 1 above on the exact same string.',
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
              if (widget.substringMatches == null)
                const SizedBox.shrink()
              else if (widget.substringMatches!.isEmpty)
                Row(
                  children: [
                    const Icon(Icons.search_off, color: AppTheme.bearishColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'NOT FOUND anywhere in this string',
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
                    Row(
                      children: [
                        const Icon(Icons.search, color: AppTheme.bullishColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'FOUND ${widget.substringMatches!.length} match'
                          '${widget.substringMatches!.length == 1 ? '' : 'es'}',
                          style: const TextStyle(
                            color: AppTheme.bullishColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.substringMatches!.map((m) {
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
