import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/automaton/presentation/pages/automaton_page.dart';
import 'features/encoding/presentation/pages/encoding_page.dart';
import 'features/visualization/presentation/pages/home_page.dart';

/// Root navigation shell with Material 3 NavigationBar.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    AutomatonPage(),
    EncodingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppTheme.darkTheme.appBarTheme.backgroundColor,
        indicatorColor: AppTheme.bullishColor.withValues(alpha: 0.25),
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            selectedIcon: Icon(Icons.show_chart, color: AppTheme.bullishColor),
            label: 'Market Chart',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree, color: AppTheme.bullishColor),
            label: 'Automata Theory',
          ),
          NavigationDestination(
            icon: Icon(Icons.data_array),
            selectedIcon: Icon(Icons.data_array, color: AppTheme.bullishColor),
            label: 'Encoding Trace',
          ),
        ],
      ),
    );
  }
}
