import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dfa.dart';
import '../../domain/entities/nfa.dart';

/// One directed edge in a rendered automaton graph, already grouped so a
/// single (from, to) pair carries every symbol that transitions along it
/// (e.g. "U, D" instead of two overlapping arrows).
class GraphEdgeSpec {
  final int from;
  final int to;
  final String label;

  const GraphEdgeSpec({
    required this.from,
    required this.to,
    required this.label,
  });
}

/// Builds the edge list for an [Nfa], including ε-transitions, grouping
/// every (from, to) pair into one labeled arrow.
List<GraphEdgeSpec> buildNfaEdges(Nfa nfa) {
  final grouped = <(int, int), List<String>>{};
  for (final fromEntry in nfa.transitions.entries) {
    final from = fromEntry.key;
    for (final symEntry in fromEntry.value.entries) {
      final symbol = symEntry.key;
      for (final to in symEntry.value) {
        grouped.putIfAbsent((from, to), () => []).add(symbol);
      }
    }
  }
  return grouped.entries
      .map((e) => GraphEdgeSpec(from: e.key.$1, to: e.key.$2, label: e.value.join(', ')))
      .toList();
}

/// Builds the edge list for a [Dfa], grouping every (from, to) pair into
/// one labeled arrow (e.g. a state that transitions to the same target on
/// both D and F shows a single "D, F" arrow rather than two stacked ones).
List<GraphEdgeSpec> buildDfaEdges(Dfa dfa) {
  final grouped = <(int, int), List<String>>{};
  for (final fromEntry in dfa.transitions.entries) {
    final from = fromEntry.key;
    for (final symEntry in fromEntry.value.entries) {
      grouped.putIfAbsent((from, symEntry.value), () => []).add(symEntry.key);
    }
  }
  return grouped.entries
      .map((e) => GraphEdgeSpec(from: e.key.$1, to: e.key.$2, label: e.value.join(', ')))
      .toList();
}

/// Renders a directed state diagram (circles + labeled transition arrows)
/// for either an NFA or a DFA, laid out left-to-right by BFS distance from
/// the start state so the diagram reads the same direction as the input
/// string flows through it.
///
/// No pan/zoom — the whole diagram is scaled (never enlarged, only
/// shrunk) to fit the card's width, so every state and transition is
/// visible at once without scrolling.
class AutomatonGraphView extends StatelessWidget {
  final String title;
  final IconData icon;
  final int numStates;
  final List<GraphEdgeSpec> edges;
  final int startState;
  final Set<int> acceptStates;
  final Map<int, String>? stateLabels;
  final int? activeState;
  final String caption;

  const AutomatonGraphView({
    super.key,
    required this.title,
    required this.icon,
    required this.numStates,
    required this.edges,
    required this.startState,
    required this.acceptStates,
    this.stateLabels,
    this.activeState,
    required this.caption,
  });

  /// Convenience constructor straight from an [Nfa].
  factory AutomatonGraphView.nfa({
    required Nfa nfa,
    String title = "Thompson's Construction — ε-NFA",
  }) {
    return AutomatonGraphView(
      title: title,
      icon: Icons.scatter_plot,
      numStates: nfa.numStates,
      edges: buildNfaEdges(nfa),
      startState: nfa.start,
      acceptStates: {nfa.accept},
      caption:
          'Every ε-transition the regex AST produced is drawn explicitly — nothing is collapsed.',
    );
  }

  /// Convenience constructor straight from a [Dfa]. Defaults describe the
  /// *minimized* DFA; pass [title]/[caption]/[icon] (or use
  /// [AutomatonGraphView.subsetDfa]) to describe the unminimized one.
  factory AutomatonGraphView.dfa({
    required Dfa dfa,
    int? activeState,
    String title = 'Minimized DFA',
    String caption =
        'Missing arrows mean "no candle in Σ continues the match from here" — the DFA rejects there.',
    IconData icon = Icons.hub,
  }) {
    return AutomatonGraphView(
      title: title,
      icon: icon,
      numStates: dfa.numStates,
      edges: buildDfaEdges(dfa),
      startState: dfa.start,
      acceptStates: dfa.accepts,
      stateLabels: dfa.stateLabels,
      activeState: activeState,
      caption: caption,
    );
  }

  /// The unminimized DFA straight out of Subset (Powerset) Construction --
  /// one state per *set* of NFA states (shown beneath each node). This is
  /// the middle stage between the NFA and the Minimized DFA: compare it
  /// against [AutomatonGraphView.dfa] to see exactly which states Moore's
  /// algorithm merged.
  factory AutomatonGraphView.subsetDfa({required Dfa dfa}) {
    return AutomatonGraphView.dfa(
      dfa: dfa,
      title: 'Subset DFA — before minimization',
      icon: Icons.account_tree,
      caption: 'Each state is one SET of NFA states reached together '
          '(the label beneath it) — the direct output of Subset Construction, '
          'before Moore\'s algorithm merges indistinguishable states.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = _GraphLayout(numStates: numStates, startState: startState, edges: edges);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.bullishColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.gridColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$numStates state${numStates == 1 ? '' : 's'}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 10),
            _buildLegend(theme),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                // No pan/zoom: scale the whole diagram down (never up,
                // so small diagrams don't look blown-up) to fit the
                // card's width, and size the box to match exactly —
                // every state and transition is on-screen at once.
                final availableWidth = constraints.maxWidth;
                final scale = availableWidth / layout.canvasSize.width > 1.0
                    ? 1.0
                    : availableWidth / layout.canvasSize.width;
                final displayWidth = layout.canvasSize.width * scale;
                final displayHeight = layout.canvasSize.height * scale;

                return Container(
                  width: double.infinity,
                  height: displayHeight + 16,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.gridColor),
                  ),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: displayWidth,
                    height: displayHeight,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: layout.canvasSize.width,
                        height: layout.canvasSize.height,
                        child: CustomPaint(
                          painter: _GraphPainter(
                            layout: layout,
                            edges: edges,
                            acceptStates: acceptStates,
                            startState: startState,
                            activeState: activeState,
                            stateLabels: stateLabels,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              'Every state and transition is shown at once — the diagram scales to fit your screen.',
              style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    Widget chip(Widget swatch, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch,
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textMuted)),
          ],
        );

    Widget circleSwatch(Color color, {bool doubled = false}) => SizedBox(
          width: 18,
          height: 18,
          child: CustomPaint(painter: _LegendCirclePainter(color: color, doubled: doubled)),
        );

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        chip(circleSwatch(Colors.blueAccent), 'start state'),
        chip(circleSwatch(AppTheme.bullishColor, doubled: true), 'accept state'),
        chip(circleSwatch(AppTheme.neutralColor), 'current (simulation)'),
      ],
    );
  }
}

class _LegendCirclePainter extends CustomPainter {
  final Color color;
  final bool doubled;
  const _LegendCirclePainter({required this.color, this.doubled = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, size.width / 2 - 1, paint);
    if (doubled) {
      canvas.drawCircle(center, size.width / 2 - 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LegendCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.doubled != doubled;
}

// ---------------------------------------------------------------------------
// Layout: BFS layering left-to-right from the start state.
// ---------------------------------------------------------------------------

const double _kNodeRadius = 22.0;
const double _kLayerSpacing = 108.0;
const double _kNodeSpacing = 68.0;
const double _kPadding = 60.0;

class _GraphLayout {
  final Map<int, Offset> positions = {};
  late final Size canvasSize;

  _GraphLayout({required int numStates, required int startState, required List<GraphEdgeSpec> edges}) {
    final adjacency = <int, List<int>>{};
    for (final e in edges) {
      adjacency.putIfAbsent(e.from, () => []).add(e.to);
    }

    final layer = <int, int>{};
    if (numStates > 0) {
      layer[startState] = 0;
      final queue = <int>[startState];
      var head = 0;
      while (head < queue.length) {
        final cur = queue[head++];
        final d = layer[cur]!;
        for (final next in adjacency[cur] ?? const <int>[]) {
          if (!layer.containsKey(next)) {
            layer[next] = d + 1;
            queue.add(next);
          }
        }
      }
      // States unreachable by forward BFS (shouldn't happen for a
      // construction rooted at its own start state, but keep the layout
      // total so nothing silently fails to render) get appended as their
      // own trailing layer.
      var trailing = (layer.values.isEmpty ? -1 : layer.values.reduce(math.max)) + 1;
      for (var s = 0; s < numStates; s++) {
        if (!layer.containsKey(s)) {
          layer[s] = trailing++;
        }
      }
    }

    final byLayer = <int, List<int>>{};
    for (var s = 0; s < numStates; s++) {
      byLayer.putIfAbsent(layer[s] ?? 0, () => []).add(s);
    }
    final maxLayer = byLayer.keys.isEmpty ? 0 : byLayer.keys.reduce(math.max);
    final maxPerLayer = byLayer.values.isEmpty ? 1 : byLayer.values.map((l) => l.length).reduce(math.max);

    final totalHeight = maxPerLayer * _kNodeSpacing;
    for (final entry in byLayer.entries) {
      final l = entry.key;
      final statesInLayer = entry.value;
      final layerHeight = statesInLayer.length * _kNodeSpacing;
      final yOffset = (totalHeight - layerHeight) / 2;
      for (var i = 0; i < statesInLayer.length; i++) {
        final x = _kPadding + l * _kLayerSpacing;
        final y = _kPadding + yOffset + i * _kNodeSpacing + _kNodeSpacing / 2;
        positions[statesInLayer[i]] = Offset(x, y);
      }
    }

    canvasSize = Size(
      _kPadding * 2 + maxLayer * _kLayerSpacing + _kNodeRadius * 2,
      _kPadding * 2 + totalHeight,
    );
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _GraphPainter extends CustomPainter {
  final _GraphLayout layout;
  final List<GraphEdgeSpec> edges;
  final Set<int> acceptStates;
  final int startState;
  final int? activeState;
  final Map<int, String>? stateLabels;

  _GraphPainter({
    required this.layout,
    required this.edges,
    required this.acceptStates,
    required this.startState,
    required this.activeState,
    required this.stateLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Group edges so we know which pairs have a reverse edge too, so those
    // get a visibly separated curve instead of overlapping.
    final edgesByPair = <(int, int), List<GraphEdgeSpec>>{};
    for (final e in edges) {
      edgesByPair.putIfAbsent((e.from, e.to), () => []).add(e);
    }

    for (final e in edges) {
      final hasReverse = edgesByPair.containsKey((e.to, e.from)) && e.from != e.to;
      _drawEdge(canvas, e, curveAway: hasReverse);
    }

    layout.positions.forEach((state, center) {
      _drawNode(canvas, state, center);
    });
  }

  void _drawEdge(Canvas canvas, GraphEdgeSpec e, {required bool curveAway}) {
    final from = layout.positions[e.from];
    final to = layout.positions[e.to];
    if (from == null || to == null) return;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    if (e.from == e.to) {
      _drawSelfLoop(canvas, from, e.label, linePaint);
      return;
    }

    final delta = to - from;
    final distance = delta.distance;
    final unit = distance == 0 ? const Offset(1, 0) : delta / distance;
    final normal = Offset(-unit.dy, unit.dx);

    // Curve bows away from the straight line; a pair with a reverse edge
    // bows further so the two arrows don't sit on top of each other.
    final bow = curveAway ? 26.0 : (e.from < e.to ? 0.0 : 14.0);

    final start = from + unit * _kNodeRadius;
    final end = to - unit * _kNodeRadius;
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2) + normal * bow;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
    canvas.drawPath(path, linePaint);

    // Arrowhead at the end, oriented along the curve's final tangent.
    final tangent = (end - mid);
    _drawArrowhead(canvas, end, tangent, linePaint.color);

    _drawEdgeLabel(canvas, mid, e.label);
  }

  void _drawSelfLoop(Canvas canvas, Offset center, String label, Paint paint) {
    final loopCenter = center + const Offset(0, -_kNodeRadius - 22);
    final rect = Rect.fromCenter(center: loopCenter, width: 34, height: 34);
    canvas.drawArc(rect, math.pi * 0.05, math.pi * 1.9, false, paint);

    // Arrowhead pointing back into the node (approx. bottom-right of loop).
    final arrowPoint = center + Offset(_kNodeRadius * 0.55, -_kNodeRadius * 0.85);
    _drawArrowhead(canvas, arrowPoint, const Offset(0.6, 0.8), paint.color);

    _drawEdgeLabel(canvas, loopCenter + const Offset(0, -20), label);
  }

  void _drawArrowhead(Canvas canvas, Offset tip, Offset direction, Color color) {
    final len = direction.distance == 0 ? 1.0 : direction.distance;
    final unit = direction / len;
    const arrowLength = 9.0;
    const arrowWidth = 6.0;
    final back = tip - unit * arrowLength;
    final normal = Offset(-unit.dy, unit.dx);
    final p1 = back + normal * arrowWidth;
    final p2 = back - normal * arrowWidth;

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawEdgeLabel(Canvas canvas, Offset at, String label) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = Rect.fromCenter(
      center: at,
      width: tp.width + 8,
      height: tp.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF121212).withValues(alpha: 0.9),
    );
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawNode(Canvas canvas, int state, Offset center) {
    final isStart = state == startState;
    final isAccept = acceptStates.contains(state);
    final isActive = state == activeState;

    final fillColor = isActive
        ? AppTheme.neutralColor.withValues(alpha: 0.25)
        : const Color(0xFF1E1E1E);
    final borderColor = isActive
        ? AppTheme.neutralColor
        : (isAccept ? AppTheme.bullishColor : (isStart ? Colors.blueAccent : Colors.white54));

    canvas.drawCircle(center, _kNodeRadius, Paint()..color = fillColor);
    canvas.drawCircle(
      center,
      _kNodeRadius,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 3 : 2,
    );
    if (isAccept) {
      canvas.drawCircle(
        center,
        _kNodeRadius - 5,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
    if (isStart) {
      // Short incoming stub arrow from the left with no source node.
      final stubStart = center - Offset(_kNodeRadius + 22, 0);
      final stubEnd = center - Offset(_kNodeRadius + 2, 0);
      final stubPaint = Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawLine(stubStart, stubEnd, stubPaint);
      _drawArrowhead(canvas, stubEnd, const Offset(1, 0), Colors.blueAccent);
    }

    final tp = TextPainter(
      text: TextSpan(
        text: 'q$state',
        style: TextStyle(
          color: isActive ? Colors.black : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

    // Optional subset-construction label (which NFA states this DFA state
    // represents), shown as a small caption just under the node.
    final rawLabel = stateLabels?[state];
    if (rawLabel != null && rawLabel.isNotEmpty) {
      // Minimized-DFA labels are built by joining every merged original
      // label with '∪' and can get arbitrarily long, so blind character
      // truncation used to cut mid-set-notation (e.g. "{5,6,7,8}∪{7,...").
      // Showing a merge count instead is always readable.
      final mergedParts = rawLabel.split('∪');
      final display = mergedParts.length > 1
          ? '${mergedParts.length} sets merged'
          : (rawLabel.length > 18 ? '${rawLabel.substring(0, 17)}…' : rawLabel);
      final labelTp = TextPainter(
        text: TextSpan(
          text: display,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 8.5, fontFamily: 'monospace'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelTp.paint(
        canvas,
        center + Offset(-labelTp.width / 2, _kNodeRadius + 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.activeState != activeState ||
        oldDelegate.acceptStates != acceptStates;
  }
}
