import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/analysis_result.dart';
import '../bloc/analysis_bloc.dart';
import '../bloc/analysis_event.dart';
import '../bloc/analysis_state.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/pattern_card.dart';

/// Main screen of the CandleLang app.
///
/// Shows a candlestick chart, the encoded string, summary stats,
/// and a scrollable list of detected patterns with ML confidence scores.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CandleLang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Re-run analysis',
            onPressed: () {
              context.read<AnalysisBloc>().add(const RunAnalysisRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<AnalysisBloc, AnalysisState>(
        builder: (context, state) {
          if (state is AnalysisInitial) {
            return _buildWelcome(context);
          }
          if (state is AnalysisLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Running CandleLang pipeline…'),
                ],
              ),
            );
          }
          if (state is AnalysisError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppTheme.bearishColor),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<AnalysisBloc>()
                          .add(const RunAnalysisRequested()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final result = (state as AnalysisLoaded).result;
          return _buildResults(context, result);
        },
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.candlestick_chart,
              size: 72, color: AppTheme.bullishColor.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(
            'CandleLang',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Formal language theory meets stock analysis',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              context.read<AnalysisBloc>().add(const RunAnalysisRequested());
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run Analysis'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, AnalysisResult result) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        // Header stats.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${result.symbol}  •  ${result.numCandles} candles',
            style: theme.textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            result.dateRange,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppTheme.textMuted),
          ),
        ),

        // Candlestick chart.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CandlestickChart(candles: result.candles),
            ),
          ),
        ),

        // Encoded string preview.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Encoded String',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    result.encodedString,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.encodedString.length} symbols',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Pattern results header.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Detected Patterns (${result.patterns.length})',
            style: theme.textTheme.titleMedium,
          ),
        ),

        // Pattern cards.
        ...result.patterns.map((p) => PatternCard(pattern: p)),

        const SizedBox(height: 24),
      ],
    );
  }
}
