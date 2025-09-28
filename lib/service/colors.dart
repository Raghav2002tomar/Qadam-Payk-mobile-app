// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand key colors (updated to match design)
  static const Color seedPrimary =  Color(0xFF008955); // Brand Green
  static const Color seedSecondary = Color(0xFF66BB6A); // Light Green 400
  static const Color seedTertiary = Color(0xFFFF8A65); // Deep Orange 300 (promo)

  // Optional: enable true black for dark surfaces (AMOLED)
  static const bool useTrueBlackDark = false;


  // Additional colors for the ride app
  static const Color activeGreen = Color(0xFF00C569);
  static const Color cardBackground = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color starColor = Color(0xFFFFC107);

  // Base text weights; face supplied by GoogleFonts
  static const TextTheme _weights = TextTheme(
    headlineLarge: TextStyle(fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontWeight: FontWeight.w500),
  );

  static ThemeData light() {
    // Build a seeded scheme and lock primary/secondary/tertiary to brand keys
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: seedPrimary,
      brightness: Brightness.light,
    ).copyWith(
      primary: seedPrimary,
      secondary: seedSecondary,
      tertiary: seedTertiary,
    );

    final textTheme = GoogleFonts.nunitoTextTheme(ThemeData.light().textTheme)
        .merge(_weights); // keep weights while using Nunito

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: base,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: base.surface,
        foregroundColor: base.onSurface,
        centerTitle: true,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: base.onPrimary,
          backgroundColor: base.primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: base.onPrimary,
          backgroundColor: base.primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: base.primary,
          side: BorderSide(color: base.outline),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.primary, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: base.surfaceContainerHigh,
        selectedColor: base.secondaryContainer,
        labelStyle: TextStyle(color: base.onSurface),
        selectedShadowColor: base.shadow,
      ),
      cardTheme: CardThemeData(
        color: base.surface,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0.5,
      ),
      dividerTheme: DividerThemeData(color: base.outlineVariant, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: base.inverseSurface,
        contentTextStyle: TextStyle(color: base.onInverseSurface),
        actionTextColor: base.tertiary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: base.surface,
        selectedItemColor: base.primary,
        unselectedItemColor: base.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: base.onSurfaceVariant,
        selectedColor: base.primary,
        selectedTileColor: base.secondaryContainer.withOpacity(0.24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: base.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData dark() {
    var base = ColorScheme.fromSeed(
      seedColor: seedPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: seedPrimary,
      secondary: seedSecondary,
      tertiary: seedTertiary,
    );

    if (useTrueBlackDark) {
      base = base.copyWith(
        surface: const Color(0xFF000000),
        surfaceDim: const Color(0xFF000000),
        surfaceBright: const Color(0xFF121212),
        background: const Color(0xFF000000),
        surfaceContainerLowest: const Color(0xFF000000),
        surfaceContainerLow: const Color(0xFF0A0A0A),
        surfaceContainer: const Color(0xFF0E0E0E),
        surfaceContainerHigh: const Color(0xFF121212),
        surfaceContainerHighest: const Color(0xFF151515),
      );
    }

    final textTheme = GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme)
        .merge(_weights);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: base,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: base.surface,
        foregroundColor: base.onSurface,
        centerTitle: true,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: base.onPrimary,
          backgroundColor: base.primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: base.onPrimary,
          backgroundColor: base.primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: base.primary,
          side: BorderSide(color: base.outline),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.primary, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: base.surfaceContainerHigh,
        selectedColor: base.secondaryContainer,
        labelStyle: TextStyle(color: base.onSurface),
        selectedShadowColor: base.shadow,
      ),
      cardTheme: CardThemeData(
        color: base.surface,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0.3,
      ),
      dividerTheme: DividerThemeData(color: base.outlineVariant, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: base.inverseSurface,
        contentTextStyle: TextStyle(color: base.onInverseSurface),
        actionTextColor: base.tertiary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: base.surface,
        selectedItemColor: base.primary,
        unselectedItemColor: base.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: base.onSurfaceVariant,
        selectedColor: base.primary,
        selectedTileColor: base.secondaryContainer.withOpacity(0.22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: base.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
