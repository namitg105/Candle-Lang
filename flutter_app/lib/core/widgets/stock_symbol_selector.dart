import 'package:flutter/material.dart';

import '../constants/supported_symbols.dart';
import '../theme/app_theme.dart';

/// Horizontal, scrollable chip row (plus a free-text box) for picking
/// which stock ticker the fetch -> encode -> detect -> score pipeline
/// should run on next.
///
/// Twelve Data's `time_series` endpoint isn't restricted to a fixed list
/// of symbols -- it will fetch ANY valid ticker you send it, free tier
/// included. [SupportedSymbols.all] is just this app's own shortlist of
/// "symbols we recommend", shown as quick-tap chips. The text box next to
/// them lets the user type any OTHER symbol; if the backend doesn't
/// recognise it, the existing error path already shown on each screen
/// (see [AnalysisError] / [EncodingError]) surfaces a clear "data not
/// available" message instead of crashing.
///
/// Deliberately dumb (SRP): it only reports which symbol was chosen or
/// typed. The caller decides what "selected" means and what to do about
/// it -- usually dispatching a BLoC event to re-run its pipeline for the
/// new symbol. Shared under `core/` (not a single feature) because both
/// the Market Chart screen and the Encoding Trace screen need the
/// identical picker.
class StockSymbolSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const StockSymbolSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...SupportedSymbols.all.map((symbol) {
                final isSelected = symbol == selected;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(symbol),
                    selected: isSelected,
                    selectedColor: AppTheme.bullishColor.withValues(alpha: 0.2),
                    onSelected: (wasSelected) {
                      if (wasSelected && !isSelected) onSelected(symbol);
                    },
                  ),
                );
              }),
              // Free-text entry for any symbol NOT in the recommended
              // list above -- suggests the recommended symbols as you
              // type, but will happily submit anything.
              SizedBox(
                width: 170,
                child: Autocomplete<String>(
                  optionsBuilder: (textEditingValue) {
                    final query = textEditingValue.text.trim().toUpperCase();
                    if (query.isEmpty) return const Iterable<String>.empty();
                    return SupportedSymbols.all
                        .where((symbol) => symbol.contains(query));
                  },
                  onSelected: (symbol) => onSelected(symbol),
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Type any symbol…',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onSubmitted: (value) {
                        final symbol = value.trim().toUpperCase();
                        if (symbol.isNotEmpty) onSelected(symbol);
                        onFieldSubmitted();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
