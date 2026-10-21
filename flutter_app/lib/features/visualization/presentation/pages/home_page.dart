import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../encoding/domain/entities/candle.dart';
import '../../domain/entities/analysis_result.dart';
import '../bloc/analysis_bloc.dart';
import '../bloc/analysis_event.dart';
import '../bloc/analysis_state.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/pattern_card.dart';

/// Main screen of the CandleLang app.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _highlightStart;
  int? _highlightEnd;
  Color? _highlightColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CandleLang Market Analyzer'),
        actions: [
          if (_highlightStart != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear highlight',
              onPressed: () {
                setState(() {
                  _highlightStart = null;
                  _highlightEnd = null;
                  _highlightColor = null;
                });
              },
            ),
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
        // Header stats
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                '${result.symbol}  •  ${result.numCandles} candles',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              if (_highlightStart != null && _highlightEnd != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (_highlightColor ?? AppTheme.bullishColor)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _highlightColor ?? AppTheme.bullishColor),
                  ),
                  child: Text(
                    'Highlight: [$_highlightStart–$_highlightEnd)',
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            result.dateRange,
            style:
                theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
          ),
        ),

        // Exact values for checking the app against the provider response.
        if (result.candles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _LatestCandleCheck(candle: result.candles.last),
          ),

        // Interactive Candlestick chart
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CandlestickChart(
                candles: result.candles,
                highlightStart: _highlightStart,
                highlightEnd: _highlightEnd,
                highlightColor: _highlightColor,
              ),
            ),
          ),
        ),

        // Encoded string preview
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Encoded String (Σ = {U, D, F, G})',
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
                    '${result.encodedString.length} symbols total',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Pattern results header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Text(
                'Detected Patterns (${result.patterns.length})',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              const Text(
                '• Tap a match to highlight on chart',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),

        // Pattern cards
        ...result.patterns.map(
          (p) => PatternCard(
            pattern: p,
            selectedStart: _highlightStart,
            selectedEnd: _highlightEnd,
            onSelectMatch: (start, end, isBullish) {
              setState(() {
                _highlightStart = start;
                _highlightEnd = end;
                _highlightColor =
                    isBullish ? AppTheme.bullishColor : AppTheme.bearishColor;
              });
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  content: Text(
                      'Highlighted ${p.displayName} match [$start–$end) on chart'),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

/// Shows the exact newest OHLC values so users can compare them with the
/// newest object in Twelve Data's `values` response.
class _LatestCandleCheck extends StatelessWidget {
  final Candle candle;

  const _LatestCandleCheck({required this.candle});

  @override
  Widget build(BuildContext context) {
    final fields = [
      ('Open', candle.open),
      ('High', candle.high),
      ('Low', candle.low),
      ('Close', candle.close),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Live feed',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text('Newest candle: ${candle.date}',
                style: const TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: fields
                  .map(
                    (field) => Text(
                      '${field.$1}: ${field.$2.toStringAsFixed(2)}',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
