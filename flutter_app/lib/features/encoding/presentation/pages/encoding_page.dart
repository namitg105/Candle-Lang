import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/supported_symbols.dart';
import '../../../../core/widgets/stock_symbol_selector.dart';
import '../bloc/encoding_bloc.dart';
import '../bloc/encoding_event.dart';
import '../bloc/encoding_state.dart';
import '../widgets/encoding_trace_table.dart';
import '../widgets/encoded_string_card.dart';

/// Page that displays the encoding results: the encoded string
/// and a per-candle trace table.
class EncodingPage extends StatefulWidget {
  const EncodingPage({super.key});

  @override
  State<EncodingPage> createState() => _EncodingPageState();
}

class _EncodingPageState extends State<EncodingPage> {
  String _selectedSymbol = SupportedSymbols.defaultSymbol;

  void _fetchAndEncode() {
    context
        .read<EncodingBloc>()
        .add(FetchAndEncodeRequested(symbol: _selectedSymbol));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CandleLang Encoding')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: StockSymbolSelector(
              selected: _selectedSymbol,
              onSelected: (symbol) {
                setState(() => _selectedSymbol = symbol);
                _fetchAndEncode();
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<EncodingBloc, EncodingState>(
              builder: (context, state) {
                if (state is EncodingInitial) {
                  return Center(
                    child: ElevatedButton.icon(
                      onPressed: _fetchAndEncode,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Fetch & Encode'),
                    ),
                  );
                }

                if (state is EncodingLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is EncodingError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48,
                              color: Theme.of(context).colorScheme.error),
                          const SizedBox(height: 16),
                          Text(state.message, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchAndEncode,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is EncodingLoaded) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      EncodedStringCard(encoded: state.result.encoded),
                      const SizedBox(height: 16),
                      _ThresholdSummary(
                        bodyThreshold: state.result.bodyThreshold,
                        gapThreshold: state.result.gapThreshold,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Encoding Trace (${state.result.trace.length} candles)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      EncodingTraceTable(
                        trace: state.result.trace,
                        candles: state.result.candles,
                        bodyThreshold: state.result.bodyThreshold,
                        gapThreshold: state.result.gapThreshold,
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Plain-language summary of the two calibrated cutoffs that decide every
/// symbol in the trace table below -- shown once, up top, so the "why"
/// behind 120 rows of U/D/F/G doesn't have to be re-derived row by row.
class _ThresholdSummary extends StatelessWidget {
  final double bodyThreshold;
  final double gapThreshold;

  const _ThresholdSummary({
    required this.bodyThreshold,
    required this.gapThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final bodyPct = (bodyThreshold * 100).toStringAsFixed(2);
    final gapPct = (gapThreshold * 100).toStringAsFixed(2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How every symbol below was calculated',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '1. Body % = |close − open| ÷ open.\n'
              '   If body % ≤ $bodyPct% → flat (F).\n'
              '   Otherwise: close ≥ open → up (U); open > close → down (D).',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              '2. Gap % = |open − previous close| ÷ previous close.\n'
              '   If gap % > $gapPct% → gap (G), no matter what the body looks like.',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              '$bodyPct% and $gapPct% are NOT fixed numbers -- they\'re recalculated '
              'every run from this stock\'s own average move, so a calm stock and a '
              'volatile one both get a fair cutoff. See the "How it was calculated" '
              'column below for the exact comparison behind every single candle.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
