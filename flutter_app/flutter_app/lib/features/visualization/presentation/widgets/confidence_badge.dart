import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Displays an ML confidence score as a color-coded chip.
///
/// Color coding:
/// - Green  (≥ 0.7) → High confidence
/// - Amber  (≥ 0.4) → Medium confidence
/// - Red    (< 0.4) → Low confidence
class ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const ConfidenceBadge({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final percentage = (confidence * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _badgeColor, width: 1),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(
          color: _badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color get _badgeColor {
    if (confidence >= 0.7) return AppTheme.bullishColor;
    if (confidence >= 0.4) return AppTheme.neutralColor;
    return AppTheme.bearishColor;
  }
}
