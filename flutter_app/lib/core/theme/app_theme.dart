import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF26A69A),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  // Chart colors
  static const Color bullishColor = Color(0xFF26A69A);
  static const Color bearishColor = Color(0xFFEF5350);
  static const Color neutralColor = Color(0xFFFFCA28);
  static const Color gridColor = Color(0xFF2A2A2A);
  static const Color textMuted = Color(0x61FFFFFF);
}
