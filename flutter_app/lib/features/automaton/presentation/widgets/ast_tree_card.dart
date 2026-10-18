import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/regex_node.dart';

/// Renders the regex string and its parsed Abstract Syntax Tree.
class AstTreeCard extends StatelessWidget {
  final String regex;
  final RegexNode ast;

  const AstTreeCard({
    super.key,
    required this.regex,
    required this.ast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree, size: 20, color: Colors.amberAccent),
                const SizedBox(width: 8),
                Text(
                  'Regex AST Hierarchy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.gridColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Pattern: ',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                      Text(
                        '/$regex/',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: AppTheme.bullishColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Text(
                    _formatAst(ast, 0),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAst(RegexNode node, int depth) {
    final indent = '  ' * depth;
    return switch (node) {
      CharNode(:final value) => '$indent└── Char("$value")',
      EpsilonNode() => '$indent└── Epsilon (ε)',
      ConcatNode(:final parts) =>
        '$indent├── Concat (${parts.length} terms):\n${parts.map((p) => _formatAst(p, depth + 1)).join('\n')}',
      UnionNode(:final parts) =>
        '$indent├── Union (|):\n${parts.map((p) => _formatAst(p, depth + 1)).join('\n')}',
      StarNode(:final inner) =>
        '$indent├── Kleene Star (*):\n${_formatAst(inner, depth + 1)}',
    };
  }
}
