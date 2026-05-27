import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const seed = Color(0xFF2D6A6A);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
