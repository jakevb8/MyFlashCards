import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Available themes for MyFlashCards.
enum AppThemeType {
  /// Bold ocean blues and cyan — energetic, sporty feel.
  oceanBlue,

  /// Soft roses and warm lilac — elegant, playful feel.
  roseGarden,

  /// Slate and teal — clean, distraction-free, corporate feel.
  executive,

  /// Deep indigo and violet — the original default.
  classic,
}

class AppTheme {
  // ── Seed colours per theme ─────────────────────────────────────────────────

  static const _seeds = {
    AppThemeType.oceanBlue: (
      primary: Color(0xFF0369A1),
      secondary: Color(0xFF0891B2),
    ), // Sky-700 / Cyan-600
    AppThemeType.roseGarden: (
      primary: Color(0xFFBE185D),
      secondary: Color(0xFF9333EA),
    ), // Rose-700 / Purple-600
    AppThemeType.executive: (
      primary: Color(0xFF0F766E),
      secondary: Color(0xFF334155),
    ), // Teal-700 / Slate-700
    AppThemeType.classic: (
      primary: Color(0xFF4F46E5),
      secondary: Color(0xFF7C3AED),
    ), // Indigo-600 / Violet-600
  };

  static const _fonts = {
    AppThemeType.oceanBlue: 'Nunito',
    AppThemeType.roseGarden: 'Lato',
    AppThemeType.executive: 'IBM Plex Sans',
    AppThemeType.classic: 'Inter',
  };

  // ── Public builders ────────────────────────────────────────────────────────

  static ThemeData light([AppThemeType type = AppThemeType.classic]) =>
      _build(type, Brightness.light);

  static ThemeData dark([AppThemeType type = AppThemeType.classic]) =>
      _build(type, Brightness.dark);

  // ── Internal builder ───────────────────────────────────────────────────────

  static ThemeData _build(AppThemeType type, Brightness brightness) {
    final seed = _seeds[type]!;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed.primary,
      secondary: seed.secondary,
      brightness: brightness,
    );

    final baseText = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final textTheme = switch (_fonts[type]!) {
      'Nunito' => GoogleFonts.nunitoTextTheme(baseText),
      'Lato' => GoogleFonts.latoTextTheme(baseText),
      'IBM Plex Sans' => GoogleFonts.ibmPlexSansTextTheme(baseText),
      _ => GoogleFonts.interTextTheme(baseText),
    };

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
