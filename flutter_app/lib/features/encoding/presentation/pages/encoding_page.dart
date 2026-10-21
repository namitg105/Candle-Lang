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
                      Text(
                        'Encoding Trace (${state.result.trace.length} candles)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      EncodingTraceTable(trace: state.result.trace),
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
