import 'package:flutter/material.dart';

import '../constants/supported_symbols.dart';
import '../theme/app_theme.dart';

/// Horizontal, scrollable chip row for picking which stock ticker the
/// fetch -> encode -> detect -> score pipeline should run on next.
///
/// Deliberately dumb (SRP): it only reports which chip was tapped. The
/// caller decides what "selected" means and what to do about it -- usually
/// dispatching a BLoC event to re-run its pipeline for the new symbol.
/// Shared under `core/` (not a single feature) because both the Market
/// Chart screen and the Encoding Trace screen need the identical picker.
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SupportedSymbols.all.map((symbol) {
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
        }).toList(),
      ),
    );
  }
}
