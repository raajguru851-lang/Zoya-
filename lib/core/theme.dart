import 'package:flutter/material.dart';
import '../widgets/neon.dart';

/// Zoya ka neon dark theme. Rang badalne ho to widgets/neon.dart ke
/// NeonColors me badlo.
class AppTheme {
  static final dark = _build();
  static final light = dark; // app hamesha neon dark me chalegi

  static ThemeData _build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: NeonColors.purple,
      brightness: Brightness.dark,
    ).copyWith(
      primary: NeonColors.cyan,
      secondary: NeonColors.magenta,
      surface: NeonColors.card,
      primaryContainer: const Color(0xFF1B2B55),
      onPrimaryContainer: Colors.white,
      surfaceContainerHighest: const Color(0xFF1A1A2E),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: NeonColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: NeonColors.bg,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
