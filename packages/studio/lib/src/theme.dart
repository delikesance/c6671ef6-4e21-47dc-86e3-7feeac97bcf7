import 'package:flutter/material.dart';

/// Tokens repris de `AppTheme` de l'app (graphite neutre + violet d'action).
abstract final class StudioColors {
  static const scaffold = Color(0xFF0E0F13);
  static const card = Color(0xFF16181E);
  static const cardBorder = Color(0xFF222631);
  static const rail = Color(0xFF12141A);
  static const selected = Color(0xFF1E212A);
  static const clusterBorder = Color(0xFF272B36);
  static const containerLowest = Color(0xFF0B0C10);
  static const ghostBorder = Color(0xFF3A3F4F);
  static const muted = Color(0xFF9AA0AF);
  static const action = Color(0xFF7C5CF0);
  static const actionSoft = Color(0xFFA78BFA);
  static const brandPrimary = Color(0xFF6A0FA2);
  static const brandSecondary = Color(0xFF9B30FF);
  static const discord = Color(0xFF5865F2);
  static const inputFill = Color(0xFF1E1F22);
  static const inputBorder = Color(0xFF404249);
  static const online = Color(0xFF4ADE80);
  static const errorText = Color(0xFFFB8A9D);
  static const error = Color(0xFFF0647C);
  static const premiumGold = Color(0xFFFFC107);
  static const countChip = Color(0xFF1F222C);
}

abstract final class StudioTheme {
  static const fontFamily = 'Inter';
  static const monoFamily = 'JetBrains Mono';

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF33343B),
          brightness: Brightness.dark,
          dynamicSchemeVariant: DynamicSchemeVariant.neutral,
        ).copyWith(
          primary: StudioColors.action,
          surface: StudioColors.card,
          outlineVariant: StudioColors.cardBorder,
          onSurfaceVariant: StudioColors.muted,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: StudioColors.scaffold,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: StudioColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: StudioColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: StudioColors.inputBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: StudioColors.action,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
