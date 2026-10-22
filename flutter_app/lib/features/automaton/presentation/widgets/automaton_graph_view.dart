import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/alphabet.dart';
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

/// True when at least one DFA state is missing a transition for one of the
/// 4 alphabet symbols -- i.e. some input would currently just fall off the
/// transition table (reject) with no explicit arrow to show it.
bool dfaNeedsTrapState(Dfa dfa) {
  for (var state = 0; state < dfa.numStates; state++) {
    final defined = dfa.transitions[state]?.keys.toSet() ?? const <String>{};
    if (defined.length < Alphabet.symbols.length) return true;
  }
  return false;
}

/// Builds the edge list for a [Dfa], grouping every (from, to) pair into
/// one labeled arrow (e.g. a state that transitions to the same target on
/// both D and F shows a single "D, F" arrow rather than two stacked ones).
///
/// When [trapState] is given, every symbol a state does NOT already have a
/// real transition for is grouped and routed there instead of being left
/// undrawn -- so all 4 inputs (U, D, F, G) show up from every state,
/// either continuing the match or being rejected explicitly. The trap
/// state self-loops on all 4 symbols too (once rejected, always rejected).
List<GraphEdgeSpec> buildDfaEdges(Dfa dfa, {int? trapState}) {
  final grouped = <(int, int), List<String>>{};
  for (final fromEntry in dfa.transitions.entries) {
    final from = fromEntry.key;
    for (final symEntry in fromEntry.value.entries) {
      grouped.putIfAbsent((from, symEntry.value), () => []).add(symEntry.key);
    }
  }

  if (trapState != null) {
    for (var state = 0; state < dfa.numStates; state++) {
      final defined = dfa.transitions[state]?.keys.toSet() ?? const <String>{};
      final missing = Alphabet.symbols.where((s) => !defined.contains(s)).toList();
      if (missing.isNotEmpty) {
        grouped.putIfAbsent((state, trapState), () => []).addAll(missing);
      }
    }
    grouped[(trapState, trapState)] = List<String>.from(Alphabet.symbols);
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
///
/// A DFA diagram (built via [AutomatonGraphView.dfa] / [.subsetDfa]) can
/// toggle between two views: the default, uncluttered one (only
/// transitions that actually continue the match -- how this diagram used
/// to look) and a "show all inputs" view that adds the explicit dead/
/// reject state for every missing symbol. It starts on the default view;
/// the toggle only appears when there's actually something extra to show.
class AutomatonGraphView extends StatefulWidget {
  final String title;
  final IconData icon;
  final int numStates;

  /// Default edge set — no dead state, only real transitions.
  final List<GraphEdgeSpec> edges;

  /// Same automaton with every missing input routed to an explicit dead
  /// state, for the "show all inputs" toggle. Null for NFA views, or for
  /// a DFA that's already complete (nothing extra to toggle on).
  final List<GraphEdgeSpec>? edgesWithTrap;

  /// Id of the dead state used by [edgesWithTrap] (always == [numStates]).
  final int? trapState;

  final int startState;
  final Set<int> acceptStates;
  final int? activeState;
  final String caption;

  /// Caption shown instead of [caption] while the "show all inputs"
  /// toggle is on.
  final String? captionWithTrap;

  const AutomatonGraphView({
    super.key,
    required this.title,
    required this.icon,
    required this.numStates,
    required this.edges,
    this.edgesWithTrap,
    this.trapState,
    required this.startState,
    required this.acceptStates,
    this.activeState,
    required this.caption,
    this.captionWithTrap,
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
      caption: 'Every ε-transition the regex AST produced is drawn explicitly — '
          'nothing is collapsed. NFAs don\'t get a "dead" state like DFAs do: a '
          'thread with no matching transition just stops, while any other '
          'active threads keep going.',
    );
  }

  /// Convenience constructor straight from a [Dfa]. Defaults describe the
  /// *minimized* DFA; pass [title]/[caption]/[icon] (or use
  /// [AutomatonGraphView.subsetDfa]) to describe the unminimized one.
  factory AutomatonGraphView.dfa({
    required Dfa dfa,
    int? activeState,
    String title = 'Minimized DFA',
    String? caption,
    IconData icon = Icons.hub,
  }) {
    final needsTrap = dfaNeedsTrapState(dfa);
    final trapState = needsTrap ? dfa.numStates : null;
    return AutomatonGraphView(
      title: title,
      icon: icon,
      numStates: dfa.numStates,
      edges: buildDfaEdges(dfa),
      edgesWithTrap: needsTrap ? buildDfaEdges(dfa, trapState: trapState) : null,
      trapState: trapState,
      startState: dfa.start,
      acceptStates: dfa.accepts,
      activeState: activeState,
      caption: caption ??
          'Missing arrows mean "no candle in Σ continues the match from here" '
              '— the DFA rejects there.',
      captionWithTrap: needsTrap
          ? 'All 4 inputs (U, D, F, G) are shown from every state — several '
              'inputs sharing a target are combined on one arrow. An input '
              'that would reject the match is routed to the dashed "dead" '
              'state instead of being left undrawn.'
          : null,
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
      caption: 'Each state here is one SET of NFA states reached together — '
          'the direct output of Subset Construction, before Moore\'s '
          'algorithm merges indistinguishable states into the Minimized DFA '
          'below.',
    );
  }

  @override
  State<AutomatonGraphView> createState() => _AutomatonGraphViewState();
}

class _AutomatonGraphViewState extends State<AutomatonGraphView> {
  // Default OFF: the uncluttered view (only real transitions) is what the
  // user sees unless they explicitly ask for every input via the toggle.
  bool _showAllInputs = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasToggle = widget.edgesWithTrap != null;
    final showAll = hasToggle && _showAllInputs;

    final effectiveEdges = showAll ? widget.edgesWithTrap! : widget.edges;
    final effectiveTrapState = showAll ? widget.trapState : null;
    final effectiveCaption =
        showAll && widget.captionWithTrap != null ? widget.captionWithTrap! : widget.caption;

    final totalLayoutStates = widget.numStates + (effectiveTrapState != null ? 1 : 0);
    final layout = _GraphLayout(
      numStates: totalLayoutStates,
      startState: widget.startState,
      edges: effectiveEdges,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 20, color: AppTheme.bullishColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
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
                    '${widget.numStates} state${widget.numStates == 1 ? '' : 's'}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
                if (effectiveTrapState != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      '+1 dead state',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.redAccent),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              effectiveCaption,
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            ),
            if (hasToggle) ...[
              const SizedBox(height: 8),
              _buildToggle(theme),
            ],
            const SizedBox(height: 10),
            _buildLegend(theme, effectiveTrapState),
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
                            edges: effectiveEdges,
                            acceptStates: widget.acceptStates,
                            startState: widget.startState,
                            activeState: widget.activeState,
                            trapState: effectiveTrapState,
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

  /// Switch that flips between the default (real transitions only) and
  /// "show all inputs" (adds the dead state) views of a DFA diagram.
  Widget _buildToggle(ThemeData theme) {
    return InkWell(
      onTap: () => setState(() => _showAllInputs = !_showAllInputs),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: _showAllInputs,
            onChanged: (value) => setState(() => _showAllInputs = value),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _showAllInputs
                  ? 'Showing all inputs (incl. the dead state)'
                  : 'Showing only the inputs that continue a match',
              style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme, int? effectiveTrapState) {
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
        if (effectiveTrapState != null)
          chip(circleSwatch(Colors.redAccent.withValues(alpha: 0.75)), 'dead state (rejects)'),
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

const double _kNodeRadius = 26.0;
const double _kLayerSpacing = 128.0;
const double _kNodeSpacing = 84.0;
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
  final int? trapState;

  _GraphPainter({
    required this.layout,
    required this.edges,
    required this.acceptStates,
    required this.startState,
    required this.activeState,
    this.trapState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Group edges so we know which pairs have a reverse edge too (gets
    // pushed further apart), and group non-self-loop edges by their
    // target so every arrow converging on the same node -- e.g. several
    // different states all rejecting into one shared "dead" state --
    // fans out around it instead of stacking into one unreadable tangle.
    final edgesByPair = <(int, int), List<GraphEdgeSpec>>{};
    final edgesByTarget = <int, List<GraphEdgeSpec>>{};
    for (final e in edges) {
      edgesByPair.putIfAbsent((e.from, e.to), () => []).add(e);
      if (e.from != e.to) {
        edgesByTarget.putIfAbsent(e.to, () => []).add(e);
      }
    }
    for (final siblings in edgesByTarget.values) {
      siblings.sort((a, b) => a.from.compareTo(b.from));
    }

    for (final e in edges) {
      final hasReverse = edgesByPair.containsKey((e.to, e.from)) && e.from != e.to;

      // Wider spacing between fanned siblings (was 24px) so their labels
      // land clearly apart instead of clustering into an unreadable knot
      // when several states all reject into the same "dead" state.
      var fanBow = 0.0;
      if (e.from != e.to) {
        final siblings = edgesByTarget[e.to]!;
        final idx = siblings.indexOf(e);
        final center = (siblings.length - 1) / 2.0;
        fanBow = (idx - center) * 38.0;
      }
      final bow = fanBow + (hasReverse ? 30.0 : 0.0);

      _drawEdge(canvas, e, bow: bow);
    }

    layout.positions.forEach((state, center) {
      _drawNode(canvas, state, center);
    });
  }

  void _drawEdge(Canvas canvas, GraphEdgeSpec e, {required double bow}) {
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
    const loopRadius = 20.0;
    // Loop sits directly on top of the node -- its bottom edge touches the
    // node's top edge exactly, with no vertical gap between the two.
    final loopCenter = center + const Offset(0, -_kNodeRadius - loopRadius);

    // The gap in the circle faces straight down (toward the node it
    // belongs to), and the arrowhead below is placed at the EXACT point
    // where the stroke stops -- computed from the same angle, not
    // guessed separately -- so the arrow always sits flush in the gap
    // instead of floating off toward the node's border.
    const southAngle = math.pi / 2;
    const gapHalfAngle = 0.22;
    final startAngle = southAngle + gapHalfAngle;
    final sweepAngle = 2 * math.pi - gapHalfAngle * 2;
    final endAngle = startAngle + sweepAngle;

    final rect = Rect.fromCenter(center: loopCenter, width: loopRadius * 2, height: loopRadius * 2);
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    final tip = loopCenter +
        Offset(loopRadius * math.cos(endAngle), loopRadius * math.sin(endAngle));
    // Tangent of the circle at the arc's end point, in the direction the
    // stroke was travelling (clockwise) -- this is what makes the
    // arrowhead point naturally back into the gap rather than at an
    // arbitrary fixed angle.
    final tangent = Offset(-math.sin(endAngle), math.cos(endAngle));
    _drawArrowhead(canvas, tip, tangent, paint.color);

    _drawEdgeLabel(canvas, loopCenter + const Offset(0, -loopRadius - 3), label);
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
    final isTrap = trapState != null && state == trapState;
    final isStart = !isTrap && state == startState;
    final isAccept = !isTrap && acceptStates.contains(state);
    final isActive = !isTrap && state == activeState;

    final fillColor = isTrap
        ? const Color(0xFF2A1515)
        : (isActive
            ? AppTheme.neutralColor.withValues(alpha: 0.25)
            : const Color(0xFF1E1E1E));
    final borderColor = isTrap
        ? Colors.redAccent.withValues(alpha: 0.75)
        : (isActive
            ? AppTheme.neutralColor
            : (isAccept ? AppTheme.bullishColor : (isStart ? Colors.blueAccent : Colors.white54)));

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
        text: isTrap ? 'dead' : 'q$state',
        style: TextStyle(
          color: isActive ? Colors.black : (isTrap ? Colors.redAccent : Colors.white),
          fontSize: isTrap ? 11 : 13,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.activeState != activeState ||
        oldDelegate.acceptStates != acceptStates ||
        oldDelegate.trapState != trapState;
  }
}
