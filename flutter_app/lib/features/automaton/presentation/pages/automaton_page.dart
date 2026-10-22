import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../pattern_detection/data/datasources/pattern_definitions_source.dart';
import '../../../pattern_detection/domain/entities/pattern_definition.dart';
import '../bloc/automaton_bloc.dart';
import '../bloc/automaton_event.dart';
import '../bloc/automaton_state.dart';
import '../widgets/ast_tree_card.dart';
import '../widgets/dfa_simulator_card.dart';
import '../widgets/automaton_graph_view.dart';
import '../widgets/dfa_transition_table.dart';
import '../widgets/state_reduction_card.dart';

/// Full interactive Automata Theory visualizer.
class AutomatonPage extends StatefulWidget {
  const AutomatonPage({super.key});

  @override
  State<AutomatonPage> createState() => _AutomatonPageState();
}

class _AutomatonPageState extends State<AutomatonPage> {
  late PatternDefinition _selectedPattern;
  final TextEditingController _customRegexController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPattern = PatternDefinitionsSource.definitions.first;
    // Trigger initial inspection for first pattern
    context.read<AutomatonBloc>().add(SelectPatternRequested(_selectedPattern));
  }

  @override
  void dispose() {
    _customRegexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Automaton Theory Inspector'),
        centerTitle: true,
      ),
      body: BlocBuilder<AutomatonBloc, AutomatonState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Pattern Selector Header
              _buildPatternSelector(theme),
              const SizedBox(height: 12),

              // Custom Regex Input
              _buildCustomInput(theme),
              const SizedBox(height: 16),

              if (state is AutomatonLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),

              if (state is AutomatonError)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 40, color: AppTheme.bearishColor),
                        const SizedBox(height: 8),
                        Text(state.message, style: const TextStyle(color: AppTheme.bearishColor)),
                      ],
                    ),
                  ),
                ),

              if (state is AutomatonLoaded) ...[
                // Pattern overview chip banner
                _buildPatternBanner(state, theme),
                const SizedBox(height: 16),

                // State Reduction Card
                StateReductionCard(inspection: state.inspection),
                const SizedBox(height: 16),

                // Graphical state diagrams: actual circles + labeled
                // transition arrows for the Thompson's-Construction NFA
                // and the minimized DFA.
                AutomatonGraphView.nfa(nfa: state.inspection.nfa),
                const SizedBox(height: 16),

                // The raw Subset-Construction DFA, before minimization —
                // shown so the NFA -> Subset DFA -> Minimized DFA pipeline
                // (as named in StateReductionCard above) is fully visible.
                AutomatonGraphView.subsetDfa(dfa: state.inspection.dfa),
                const SizedBox(height: 16),

                AutomatonGraphView.dfa(
                  dfa: state.inspection.minDfa,
                  activeState: state.traceResult?.path.last,
                ),
                const SizedBox(height: 16),

                // DFA State Transition Table
                DfaTransitionTable(
                  dfa: state.inspection.minDfa,
                  activeState: state.traceResult?.path.last,
                ),
                const SizedBox(height: 16),

                // Interactive DFA Simulator
                DfaSimulatorCard(
                  inspection: state.inspection,
                  traceResult: state.traceResult,
                  substringMatches: state.substringMatches,
                  onSimulate: (input) {
                    context.read<AutomatonBloc>().add(SimulateStringRequested(input));
                  },
                ),
                const SizedBox(height: 16),

                // AST Tree Card
                AstTreeCard(
                  regex: state.patternRegex,
                  ast: state.inspection.ast,
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPatternSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Known Candlestick Pattern',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: PatternDefinitionsSource.definitions.map((p) {
              final isSelected = p.name == _selectedPattern.name;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${p.displayName} (${p.regex})'),
                  selected: isSelected,
                  selectedColor: AppTheme.bullishColor.withValues(alpha: 0.2),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedPattern = p);
                      context.read<AutomatonBloc>().add(SelectPatternRequested(p));
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomInput(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _customRegexController,
            decoration: InputDecoration(
              hintText: 'Or enter custom regex (e.g. U{2,}D|G+)',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onSubmitted: (val) {
              context.read<AutomatonBloc>().add(CustomRegexSubmitted(val));
            },
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(
          onPressed: () {
            context
                .read<AutomatonBloc>()
                .add(CustomRegexSubmitted(_customRegexController.text));
          },
          child: const Text('Parse'),
        ),
      ],
    );
  }

  Widget _buildPatternBanner(AutomatonLoaded state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.gridColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                state.patternName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.bullishColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.gridColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  state.patternRegex,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
          if (state.meaning != null) ...[
            const SizedBox(height: 4),
            Text(
              state.meaning!,
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
